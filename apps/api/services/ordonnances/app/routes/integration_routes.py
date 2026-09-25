from datetime import datetime

import httpx
from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from config import Config
from models.api_models import ErrorResponse, MessageResponse
from models.ordonnance import OrdonnanceCreate
from services.logger_service import logger_service
from services.mongodb_client import MongoDBClient
from services.pdf_service import generate_ordonnance_pdf
from services.rabbitmq_client import RabbitMQClient

router = APIRouter(prefix="/api/integration", tags=["Integration"])
security = HTTPBearer()

# Initialize services
mongodb_client = MongoDBClient(Config)
rabbitmq_client = RabbitMQClient(Config)

# MongoDB collections
ordonnances_collection = mongodb_client.db.ordonnances

# Create HTTP client with a reasonable timeout
http_client = httpx.AsyncClient(timeout=10.0)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Validate the bearer token through the auth service."""
    token = credentials.credentials
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{Config.AUTH_SERVICE_URL}/api/auth/token/verify",
                json={"token": token},
            )
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        ) from exc

    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_info = response.json()
    if not user_info.get("valid"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_info["token"] = token
    return user_info


async def get_current_doctor(
    user_info: dict = Depends(get_current_user),
) -> dict:
    """Require a doctor/admin role for prescription authoring."""
    roles = set(user_info.get("roles", []))
    if roles.isdisjoint({"doctor", "admin"}):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Doctor role required",
        )
    return user_info


@router.post(
    "/create-prescription",
    response_model=dict[str, str],
    status_code=status.HTTP_201_CREATED,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
async def create_prescription(prescription: OrdonnanceCreate, user_info: dict = Depends(get_current_doctor)):
    """Create a new prescription and notify relevant services"""
    try:
        doctor_id = user_info.get("user_id")

        # Create ordonnance document
        ordonnance_data = {
            "patient_id": prescription.patient_id,
            "patient_name": prescription.patient_name,
            "medecin_id": doctor_id,
            "medicaments": [med.dict() for med in prescription.medicaments],
            "date_creation": datetime.utcnow().isoformat(),
            "date_expiration": prescription.date_expiration,
            "notes": prescription.notes,
            "status": "created",
        }

        # Insert into database
        result = ordonnances_collection.insert_one(ordonnance_data)
        ordonnance_id = str(result.inserted_id)

        # Generate PDF
        pdf_path = generate_ordonnance_pdf(
            ordonnance_id=ordonnance_id,
            patient_name=prescription.patient_name,
            medicaments=prescription.medicaments,
            notes=prescription.notes,
            doctor_name=user_info.get("name", "Dr."),
        )

        # Update with PDF path
        ordonnances_collection.update_one({"_id": result.inserted_id}, {"$set": {"pdf_path": pdf_path}})

        # Notify about prescription creation
        rabbitmq_client.notify_prescription_created(
            prescription_id=ordonnance_id,
            doctor_id=doctor_id,
            patient_id=prescription.patient_id,
        )

        # Notify the patient
        rabbitmq_client.notify_patient_prescription(
            prescription_id=ordonnance_id,
            patient_id=prescription.patient_id,
            action="created",
        )

        return {
            "ordonnance_id": ordonnance_id,
            "message": "Prescription created successfully",
        }

    except Exception as e:
        logger_service.error(f"Error creating prescription: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {e!s}")


@router.post(
    "/update-prescription-status/{prescription_id}",
    response_model=MessageResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
async def update_prescription_status(
    prescription_id: str,
    status: str,
    pharmacy_id: str | None = None,
    user_info: dict = Depends(get_current_doctor),
):
    """Update prescription status and notify relevant services"""
    try:
        # Find prescription
        ordonnance = ordonnances_collection.find_one({"_id": ObjectId(prescription_id)})
        if not ordonnance:
            raise HTTPException(status_code=404, detail="Prescription not found")

        # Update status
        ordonnances_collection.update_one(
            {"_id": ObjectId(prescription_id)},
            {
                "$set": {
                    "status": status,
                    "updated_at": datetime.utcnow().isoformat(),
                    "pharmacy_id": pharmacy_id,
                }
            },
        )

        # Notify about status update
        if status == "dispensed":
            rabbitmq_client.notify_prescription_dispensed(prescription_id=prescription_id, pharmacy_id=pharmacy_id)

            # Notify the doctor
            rabbitmq_client.notify_doctor_prescription(
                prescription_id=prescription_id,
                doctor_id=ordonnance.get("medecin_id"),
                action=status,
            )

            # Notify the patient
            rabbitmq_client.notify_patient_prescription(
                prescription_id=prescription_id,
                patient_id=ordonnance.get("patient_id"),
                action=status,
            )

        return MessageResponse(message=f"Prescription status updated to {status}")

    except HTTPException:
        raise
    except Exception as e:
        logger_service.error(f"Error updating prescription status: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {e!s}")


@router.get(
    "/doctor-prescriptions",
    responses={500: {"model": ErrorResponse}},
)
async def get_doctor_prescriptions(user_info: dict = Depends(get_current_doctor)):
    """Get prescriptions created by a doctor"""
    try:
        doctor_id = user_info.get("user_id")

        prescriptions = list(ordonnances_collection.find({"medecin_id": doctor_id}).sort("date_creation", -1))

        # Format the response
        formatted_prescriptions = []
        for prescription in prescriptions:
            formatted_prescriptions.append(
                {
                    "id": str(prescription.get("_id")),
                    "patient_id": prescription.get("patient_id"),
                    "patient_name": prescription.get("patient_name"),
                    "date_creation": prescription.get("date_creation"),
                    "date_expiration": prescription.get("date_expiration"),
                    "status": prescription.get("status"),
                    "medicaments_count": len(prescription.get("medicaments", [])),
                    "has_pdf": "pdf_path" in prescription,
                }
            )

        return {"prescriptions": formatted_prescriptions}

    except Exception as e:
        logger_service.error(f"Error retrieving doctor prescriptions: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {e!s}")
