from fastapi import APIRouter, Depends, Header, HTTPException, Path, Query, status

from middleware.keycloak_auth import get_current_user
from models.auth import *
from services.keycloak_service import KeycloakService

# Initialize router
router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# Initialize Keycloak service
keycloak_service = KeycloakService()


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
        # Log the login attempt (without password)
        print(f"Login attempt for user: {request.email}")

        try:
            # Use KeycloakService for login
            result = keycloak_service.login(request.email, request.password)
            print(f"Login successful for user: {request.email}")
            return result
        except Exception as e:
            print(f"Keycloak login failed: {e!s}")

            # Provide user-friendly error message
            raise HTTPException(
                status_code=401,
                detail="The email or password you entered is incorrect. Please try again.",
            )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Login error: {e!s}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Authentication failed: {e!s}")


@router.post("/token/verify", response_model=TokenVerifyResponse)
async def verify_token(request: TokenRequest, requested_role: Role | None = None):
    """Verify JWT token and return user information"""
    try:
        token = request.token
        print(f"Verifying token: {token[:15]}...")

        try:
            # Verify token and get payload
            payload = keycloak_service.verify_token(token)
            print(f"Decoded token info: {payload}")

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
            print(f"Token verified for user: {user_data['email']}, role: {primary_role}")
            return user_data

        except Exception as e:
            error_msg = str(e).lower()
            print(f"Token verification failed: {e!s}")
            return {"valid": False, "error": error_msg}

    except Exception as e:
        print(f"Token verification error: {e!s}")
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
        print(f"Token refresh error: {e!s}")
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

        print(f"Registration attempt for user: {request.email}")

        # Prepare user data for registration
        user_data = {
            "email": request.email,
            "username": request.username or request.email,
            "password": request.password,
            "firstName": (request.name if request.name else ""),
            "lastName": (request.name if request.name else ""),
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
            print(f"User created successfully in Keycloak: {user_data['username']}")

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
                print(f"Auto-login after registration failed: {e!s}")
                # Still return success without tokens
                return {"message": "User registered successfully", "user_id": user_id}

        except Exception as e:
            error_message = str(e)

            if "409" in error_message or "conflict" in error_message or "already exists" in error_message:
                raise HTTPException(status_code=409, detail="Email already registered")
            elif "403" in error_message or "permission" in error_message:
                print("Permission denied. Check Keycloak client permissions.")
                raise HTTPException(
                    status_code=500,
                    detail="User registration failed: Insufficient permissions. Contact the administrator.",
                )
            else:
                raise HTTPException(status_code=500, detail=f"User registration failed: {error_message}")

    except HTTPException:
        raise
    except Exception as e:
        print(f"Registration error: {e!s}")
        raise HTTPException(status_code=500, detail=f"Registration failed: {e!s}")


@router.post(
    "/logout",
    response_model=MessageResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
async def logout(request: LogoutRequest | None = None, authorization: str = Header(None)):
    try:
        # Log the logout attempt
        print("Logout attempt received")
        refresh_token = None

        # Try to get refresh token from request body
        if request and hasattr(request, "refresh_token") and request.refresh_token:
            refresh_token = request.refresh_token
            print(f"Logout with refresh token from body: {refresh_token[:10]}...")
        # If no refresh token in body, try to extract from Authorization header
        elif authorization:
            token = authorization.replace("Bearer ", "")
            print(f"Trying to logout with token from header: {token[:10]}...")
            try:
                # Attempt to use the access token to help with logout
                keycloak_service.logout_from_access_token(token)
                print("Logout from access token successful")
            except Exception as e:
                print(f"Logout from access token failed: {e!s}")

        # Use KeycloakService for logout if we have a refresh token
        if refresh_token:
            try:
                keycloak_service.logout(refresh_token)
                print("Logout with refresh token successful")
            except Exception as e:
                print(f"Keycloak logout operation with refresh token failed: {e!s}")

        # Always return success to client regardless of backend result
        return {"message": "Logged out successfully"}

    except Exception as e:
        print(f"Logout error: {e!s}")
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
        print(f"Password reset error: {e!s}")
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
        print(f"Getting user info for user_id: {user_id}")
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
            print(f"Failed to get user roles: {e!s}")
            user_data["roles"] = []

        return user_data

    except HTTPException:
        raise
    except Exception as e:
        print(f"Get user error: {e!s}")
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
                    pass

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

        return [
            {
                "id": user.get("id"),
                "username": user.get("username"),
                "email": user.get("email"),
                "firstName": user.get("firstName"),
                "lastName": user.get("lastName"),
                "enabled": user.get("enabled", True),
                "attributes": user.get("attributes", {}),
            }
            for user in users
        ]
    except HTTPException:
        raise
    except Exception as e:
        print(f"Get users error: {e!s}")
        raise HTTPException(status_code=500, detail="Failed to retrieve users")


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

        print(f"Getting profile for user: {user_id}")

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

        # Add roles information
        user_data["roles"] = user_info.get("roles", [])

        # Add role information
        user_data["role"] = user_info.get("primary_role")

        return user_data

    except HTTPException:
        raise
    except Exception as e:
        print(f"Get profile error: {e!s}")
        raise HTTPException(status_code=500, detail=f"Failed to get profile: {e!s}")
