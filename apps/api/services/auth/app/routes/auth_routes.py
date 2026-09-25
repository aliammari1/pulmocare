import json
import logging

from fastapi import APIRouter, Depends, Header, HTTPException, Path, Query, status

from middleware.keycloak_auth import get_current_user
from models.auth import *
from services.keycloak_service import KeycloakService

# Initialize router
router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# Initialize Keycloak service
keycloak_service = KeycloakService()
logger = logging.getLogger(__name__)


def _realm_roles(user_info: dict) -> list[str]:
    return [str(role) for role in user_info.get("realm_access", {}).get("roles", [])]


def _primary_role(user_info: dict) -> Role | None:
    roles = set(_realm_roles(user_info))
    for role in (Role.ADMIN, Role.DOCTOR, Role.RADIOLOGIST, Role.PATIENT):
        if role.value in roles:
            return role
    return None


def _split_name(name: str) -> tuple[str, str]:
    parts = name.strip().split()
    if not parts:
        return "", ""
    return parts[0], " ".join(parts[1:])


def _first_keycloak_attribute(attributes: dict, name: str) -> str:
    value = attributes.get(name)
    if isinstance(value, list):
        return str(value[0]) if value else ""
    return str(value) if value is not None else ""


@router.post(
    "/login",
    response_model=LoginResponse,
    responses={
        400: {"model": ErrorResponse},
        401: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def login(request: LoginRequest):
    try:

        try:
            # Use KeycloakService for login
            result = keycloak_service.login(request.email, request.password)
            return result
        except Exception as e:
            logger.info("Login rejected by identity provider")

            # Provide user-friendly error message
            raise HTTPException(
                status_code=401,
                detail="The email or password you entered is incorrect. Please try again.",
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unexpected login failure")
        raise HTTPException(status_code=500, detail=f"Authentication failed: {e!s}")


@router.post("/token/verify", response_model=TokenVerifyResponse)
async def verify_token(request: TokenRequest, requested_role: Role | None = None):
    """Verify JWT token and return user information"""
    try:
        token = request.token

        try:
            # Verify token and get payload
            payload = keycloak_service.verify_token(token)
    
            # Get all realm roles from the token
            all_realm_roles = payload.get("realm_access", {}).get("roles", [])

            # Extract core user data
            user_data = {
                "valid": True,
                "user_id": payload.get("sub"),
                "email": payload.get("email"),
                "name": payload.get("name"),
                "roles": all_realm_roles,
                "expires_at": payload.get("exp"),
            }

            # Determine primary role
            realm_roles = all_realm_roles
            primary_role = None

            # Use requested role if user has it
            if requested_role and requested_role.value in realm_roles:
                primary_role = requested_role
            else:
                # Otherwise select highest priority role
                for role in [Role.ADMIN, Role.DOCTOR, Role.RADIOLOGIST, Role.PATIENT]:
                    if role.value in realm_roles:
                        primary_role = role
                        break

            user_data["primary_role"] = primary_role
                return user_data

        except Exception as e:
            error_msg = str(e).lower()
            logger.info("Token verification rejected")
            return {"valid": False, "error": error_msg}

    except Exception as e:
        logger.exception("Unexpected token verification failure")
        raise HTTPException(status_code=500, detail=f"Verification failed: {e!s}")


@router.post(
    "/token/refresh",
    response_model=RefreshTokenResponse,
    responses={
        400: {"model": ErrorResponse},
        401: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def refresh_token(request: RefreshTokenRequest):
    try:
        # Use KeycloakService for token refresh
        result = keycloak_service.refresh_token(request.refresh_token)
        return result

    except Exception as e:
        logger.info("Token refresh failed")
        raise HTTPException(status_code=401, detail="Invalid refresh token")


@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        400: {"model": ErrorResponse},
        409: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def register(request: RegisterRequest):
    try:
        # Public registration is patient-only. Provider/admin roles and verification
        # are provisioned through an authenticated administrative workflow.
        if request.role not in (None, Role.PATIENT):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Clinical staff accounts must be provisioned by an administrator",
            )
        if request.is_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification cannot be self-assigned during registration",
            )


        # Prepare user data for registration
        first_name, last_name = _split_name(request.name)
        user_data = {
            "email": request.email,
            "username": request.username or request.email,
            "password": request.password,
            "firstName": first_name,
            "lastName": last_name,
            "phone": (request.phone if request.phone else ""),
            "specialty": request.specialty if request.specialty else "",
            "address": request.address if request.address else "",
            "role": Role.PATIENT.value,
            "bio": request.bio if request.bio else "",
            "license_number": request.license_number if request.license_number else "",
            "hospital": request.hospital if request.hospital else "",
            "education": request.education if request.education else "",
            "experience": request.experience if request.experience else "",
            "signature": request.signature if request.signature else "",
            "is_verified": "false",
            "verification_details": None,
            # Add new patient fields - handle both frontend and backend field naming
            "date_of_birth": request.date_of_birth or request.date_of_birth
            if hasattr(request, "date_of_birth")
            else "",
            "blood_type": request.blood_type or request.blood_type if hasattr(request, "blood_type") else "",
            "social_security_number": (request.social_security_number if request.social_security_number else ""),
            "medical_history": (
                request.medical_history
                if request.medical_history
                else (
                    [request.medical_history]
                    if hasattr(request, "medical_history") and isinstance(request.medical_history, str)
                    else (request.medical_history if hasattr(request, "medical_history") else [])
                )
            ),
            "allergies": request.allergies if request.allergies else [],
            "height": str(request.height or request.height)
            if hasattr(request, "height") and request.height is not None
            else "",
            "weight": str(request.weight or request.weight)
            if hasattr(request, "weight") and request.weight is not None
            else "",
            "medical_files": request.medical_files
            if hasattr(request, "medical_files") and request.medical_files
            else [],
        }

        try:
            # Use KeycloakService for user registration
            user_id = keycloak_service.register(user_data)
            logger.info("User account created in identity provider")

            # Try auto-login after registration
            try:
                login_result = keycloak_service.login(request.email, request.password)

                # Return success with tokens
                return {
                    "message": "User registered successfully",
                    "user_id": user_id,
                    "access_token": login_result["access_token"],
                    "refresh_token": login_result["refresh_token"],
                    "expires_in": login_result["expires_in"],
                }
            except Exception as e:
                logger.info("Automatic login after registration failed")
                # Still return success without tokens
                return {"message": "User registered successfully", "user_id": user_id}

        except Exception as e:
            error_message = str(e)

            if "409" in error_message or "conflict" in error_message or "already exists" in error_message:
                raise HTTPException(status_code=409, detail="Email already registered")
            elif "403" in error_message or "permission" in error_message:
                logger.error("Identity provider denied registration operation")
                raise HTTPException(
                    status_code=500,
                    detail="User registration failed: Insufficient permissions. Contact the administrator.",
                )
            else:
                raise HTTPException(status_code=500, detail=f"User registration failed: {error_message}")

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unexpected registration failure")
        raise HTTPException(status_code=500, detail=f"Registration failed: {e!s}")


@router.post(
    "/logout",
    response_model=MessageResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
async def logout(request: LogoutRequest | None = None, authorization: str = Header(None)):
    try:
        # Log the logout attempt
        refresh_token = None

        # Try to get refresh token from request body
        if request and hasattr(request, "refresh_token") and request.refresh_token:
            refresh_token = request.refresh_token
        # If no refresh token in body, try to extract from Authorization header
        elif authorization:
            token = authorization.replace("Bearer ", "")
            try:
                # Attempt to use the access token to help with logout
                keycloak_service.logout_from_access_token(token)
            except Exception as e:
                logger.info("Access-token logout was not completed")

        # Use KeycloakService for logout if we have a refresh token
        if refresh_token:
            try:
                keycloak_service.logout(refresh_token)
            except Exception as e:
                logger.info("Refresh-token logout was not completed")

        # Always return success to client regardless of backend result
        return {"message": "Logged out successfully"}

    except Exception as e:
        logger.exception("Unexpected logout failure")
        # Return success even if we couldn't process the request properly
        # This is to ensure the client can continue with their logout flow
        return {"message": "Logged out successfully"}


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
async def forgot_password(request: ForgotPasswordRequest):
    try:
        # Use KeycloakService for password reset
        keycloak_service.request_password_reset(request.email)
        return {"message": "Password reset email sent successfully"}
    except Exception as e:
        logger.info("Password-reset request was not completed")
        # For security, always return the same message regardless of outcome
        return {"message": "If your email is registered, you will receive a password reset link"}


@router.get(
    "/user/{user_id}",
    responses={
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def get_user(user_id: str = Path(...), user_info: dict = Depends(get_current_user)):
    try:
        # Check if requesting own info or has admin role
        if user_id != user_info.get("sub") and "admin" not in user_info.get("realm_access", {}).get("roles", []):
            raise HTTPException(status_code=403, detail="Unauthorized")

        # Use KeycloakService to get user information
        user_data = keycloak_service.get_user_info_by_id(user_id)

        # Clean up sensitive data
        if "credentials" in user_data:
            del user_data["credentials"]

        if "access" in user_data:
            del user_data["access"]

        # Get user roles if possible
        try:
            # This would require implementing a method in KeycloakService to get user roles
            # For now, we'll use the roles from the token
            user_data["roles"] = user_info.get("realm_access", {}).get("roles", [])
        except Exception as e:
            logger.info("Unable to read user roles from identity provider")
            user_data["roles"] = []

        return user_data

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unable to retrieve user profile")
        raise HTTPException(status_code=500, detail=f"Failed to get user info: {e!s}")


@router.get(
    "/users",
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def get_users_by_role(
    role: Role | None = None,
    first: int = Query(0, ge=0),
    max: int = Query(10, ge=1, le=100),
    user_info: dict = Depends(get_current_user),
):
    """List users for authenticated clinical staff.

    Raw Keycloak credential/access metadata is never returned. Patient accounts
    may not enumerate other users.
    """
    requester_roles = user_info.get("realm_access", {}).get("roles", [])
    if not any(allowed in requester_roles for allowed in (Role.DOCTOR.value, Role.RADIOLOGIST.value, Role.ADMIN.value)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Clinical staff role required",
        )

    try:
        if role:
            role_name = role.value
            users = keycloak_service.keycloak_admin.get_users({})
            filtered_users = []

            for user in users:
                user_id = user.get("id")
                has_role = False
                try:
                    realm_roles = keycloak_service.keycloak_admin.get_realm_roles_of_user(user_id)
                    has_role = role_name in {item.get("name") for item in realm_roles}
                except Exception:
                    logger.debug("Falling back to legacy role attribute")

                if not has_role:
                    # Fall back to the explicit role attribute for older accounts.
                    attributes = user.get("attributes", {})
                    attribute_role = attributes.get("role")
                    if isinstance(attribute_role, list):
                        attribute_role = attribute_role[0] if attribute_role else None
                    has_role = attribute_role == role_name

                if has_role:
                    filtered_users.append(user)

            users = filtered_users[first : first + max]
        else:
            users = keycloak_service.keycloak_admin.get_users({"first": first, "max": max})

        def _safe_directory_attributes(user: dict) -> dict:
            attributes = user.get("attributes", {}) or {}
            safe_attributes = {}
            for key in ("phone",):
                value = attributes.get(key)
                if value is not None:
                    safe_attributes[key] = value
            return safe_attributes

        return [
            {
                "id": user.get("id"),
                "username": user.get("username"),
                "email": user.get("email"),
                "firstName": user.get("firstName"),
                "lastName": user.get("lastName"),
                "enabled": user.get("enabled", True),
                "attributes": _safe_directory_attributes(user),
            }
            for user in users
        ]
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unable to retrieve user directory")
        raise HTTPException(status_code=500, detail="Failed to retrieve users")


@router.get("/patients/{patient_id}/contact")
async def get_patient_contact(
    patient_id: str = Path(...),
    user_info: dict = Depends(get_current_user),
):
    """Return minimal patient contact data to authenticated clinical staff."""
    requester_roles = set(_realm_roles(user_info))
    if requester_roles.isdisjoint(
        {Role.DOCTOR.value, Role.RADIOLOGIST.value, Role.ADMIN.value}
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Clinical staff role required",
        )

    try:
        patient = keycloak_service.get_user_info_by_id(patient_id)
        patient_roles = keycloak_service.keycloak_admin.get_realm_roles_of_user(
            patient_id
        )
        if Role.PATIENT.value not in {role.get("name") for role in patient_roles}:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient not found",
            )

        return {
            "email": patient.get("email") or "",
            "name": " ".join(
                part
                for part in (
                    str(patient.get("firstName") or "").strip(),
                    str(patient.get("lastName") or "").strip(),
                )
                if part
            ).strip(),
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found",
        )


@router.get("/providers")
async def get_provider_directory(
    provider_type: Role | None = None,
    first: int = Query(0, ge=0),
    max: int = Query(50, ge=1, le=100),
    user_info: dict = Depends(get_current_user),
):
    """Return a minimal authenticated directory of clinical providers."""
    del user_info

    if provider_type not in (None, Role.DOCTOR, Role.RADIOLOGIST):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="provider_type must be doctor or radiologist",
        )

    requested_roles = (
        {provider_type.value}
        if provider_type is not None
        else {Role.DOCTOR.value, Role.RADIOLOGIST.value}
    )

    try:
        users = keycloak_service.keycloak_admin.get_users({})
        providers = []
        for user in users:
            user_id = user.get("id")
            if not user_id or not user.get("enabled", True):
                continue

            try:
                realm_roles = keycloak_service.keycloak_admin.get_realm_roles_of_user(
                    user_id
                )
                roles = {item.get("name") for item in realm_roles}
            except Exception:
                roles = set()
                attribute_role = (user.get("attributes", {}) or {}).get("role")
                if isinstance(attribute_role, list):
                    roles.update(str(value) for value in attribute_role)
                elif attribute_role:
                    roles.add(str(attribute_role))

            matched_roles = requested_roles & roles
            if not matched_roles:
                continue

            provider_role = (
                Role.DOCTOR.value
                if Role.DOCTOR.value in matched_roles
                else Role.RADIOLOGIST.value
            )
            attributes = user.get("attributes", {}) or {}

            display_name = " ".join(
                part
                for part in (
                    str(user.get("firstName") or "").strip(),
                    str(user.get("lastName") or "").strip(),
                )
                if part
            ).strip()
            if not display_name:
                display_name = str(user.get("username") or "Clinical provider")

            providers.append(
                {
                    "id": user_id,
                    "name": display_name,
                    "provider_type": provider_role,
                    "specialty": _first_keycloak_attribute(attributes, "specialty"),
                    "hospital": _first_keycloak_attribute(attributes, "hospital"),
                }
            )

        providers.sort(key=lambda item: item["name"].lower())
        return providers[first : first + max]
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve provider directory",
        )


@router.get(
    "/profile",
    responses={
        401: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def get_profile(user_info: dict = Depends(get_current_user)):
    """
    Get the current logged-in user's profile information.

    Returns the complete user profile including all attributes.
    """
    try:
        # Extract user ID from the token
        user_id = user_info.get("user_id")
        if not user_id:
            raise HTTPException(status_code=404, detail="User ID not found in token")


        # Use KeycloakService to get user information
        user_data = keycloak_service.get_user_info_by_id(user_id)

        if not user_data:
            raise HTTPException(status_code=404, detail="User profile not found")

        # Clean up sensitive data
        if "credentials" in user_data:
            del user_data["credentials"]

        if "access" in user_data:
            del user_data["access"]

        # Format attributes correctly - convert list values to single values for client
        attributes = user_data.get("attributes", {})
        formatted_attributes = {}

        for key, value in attributes.items():
            # Handle array values from Keycloak by using the first item
            if isinstance(value, list) and len(value) > 0:
                formatted_attributes[key] = value[0]
            else:
                formatted_attributes[key] = value

        # Replace attributes with formatted version
        user_data["attributes"] = formatted_attributes

        # Add normalized role information from the verified JWT.
        user_data["roles"] = _realm_roles(user_info)
        primary_role = _primary_role(user_info)
        user_data["role"] = primary_role.value if primary_role else None

        return user_data

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unable to retrieve authenticated profile")
        raise HTTPException(status_code=500, detail=f"Failed to get profile: {e!s}")


@router.put("/profile", response_model=MessageResponse)
async def update_profile(
    request: ProfileUpdateRequest,
    user_info: dict = Depends(get_current_user),
):
    user_id = user_info.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user is missing an ID",
        )

    update_data: dict[str, object] = {}
    if request.name is not None:
        first_name, last_name = _split_name(request.name)
        update_data["firstName"] = first_name
        update_data["lastName"] = last_name
    if request.phone is not None:
        update_data["phone"] = request.phone.strip()
    if request.address is not None:
        update_data["address"] = request.address.strip()
    if request.profile_image is not None:
        update_data["profile_image"] = request.profile_image

    role = _primary_role(user_info)
    if request.specialty is not None:
        if role not in (Role.DOCTOR, Role.RADIOLOGIST, Role.ADMIN):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only clinical staff can set a specialty",
            )
        update_data["specialty"] = request.specialty.strip()

    if not update_data:
        raise HTTPException(status_code=400, detail="No profile changes supplied")

    try:
        keycloak_service.update_user(user_id, update_data)
        return {"message": "Profile updated successfully"}
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to update profile")


@router.put("/profile/signature", response_model=MessageResponse)
async def update_signature(
    request: SignatureUpdateRequest,
    user_info: dict = Depends(get_current_user),
):
    role = _primary_role(user_info)
    if role not in (Role.DOCTOR, Role.RADIOLOGIST, Role.ADMIN):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="A clinical staff role is required to store a signature",
        )

    user_id = user_info.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user is missing an ID",
        )

    try:
        keycloak_service.update_user(user_id, {"signature": request.signature})
        return {"message": "Signature updated successfully"}
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to update signature")


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    request: ChangePasswordRequest,
    user_info: dict = Depends(get_current_user),
):
    user_id = user_info.get("user_id")
    email = user_info.get("email") or user_info.get("preferred_username")
    if not user_id or not email:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user identity is incomplete",
        )
    if request.current_password == request.new_password:
        raise HTTPException(
            status_code=400,
            detail="New password must be different from the current password",
        )

    try:
        keycloak_service.change_password(
            user_id,
            email,
            request.current_password,
            request.new_password,
        )
        return {"message": "Password updated successfully"}
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Current password is incorrect or the new password was rejected",
        )


@router.post("/profile/verification", response_model=MessageResponse)
async def submit_verification(
    request: VerificationRequest,
    user_info: dict = Depends(get_current_user),
):
    role = _primary_role(user_info)
    if role not in (Role.DOCTOR, Role.RADIOLOGIST):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only clinical staff accounts can submit verification documents",
        )

    user_id = user_info.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user is missing an ID",
        )

    details = {
        "status": "pending",
        "document_bucket": request.document_bucket,
        "document_object_name": request.document_object_name,
    }
    try:
        keycloak_service.update_user(
            user_id,
            {
                "is_verified": False,
                "verification_details": json.dumps(details),
            },
        )
        return {"message": "Verification document submitted for review"}
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to submit verification")


@router.post("/users/{user_id}/verification", response_model=MessageResponse)
async def decide_verification(
    request: VerificationDecisionRequest,
    user_id: str = Path(...),
    user_info: dict = Depends(get_current_user),
):
    if Role.ADMIN.value not in _realm_roles(user_info):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator role required",
        )

    details = {
        "status": "approved" if request.approved else "rejected",
        "review_note": request.note or "",
        "reviewed_by": user_info.get("user_id"),
    }
    try:
        keycloak_service.update_user(
            user_id,
            {
                "is_verified": request.approved,
                "verification_details": json.dumps(details),
            },
        )
        return {
            "message": (
                "Provider verification approved"
                if request.approved
                else "Provider verification rejected"
            )
        }
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Failed to update verification status",
        )
