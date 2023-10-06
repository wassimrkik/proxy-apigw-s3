import requests
import jwt
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import base64
from datetime import datetime

# Your Auth0 domain and token to validate
AUTH0_DOMAIN = 'study-service.uk.auth0.com'
TOKEN = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InRFZkFrN0hQNjJsZEQzM0FxLVFvUiJ9.eyJpc3MiOiJodHRwczovL3N0dWR5LXNlcnZpY2UudWsuYXV0aDAuY29tLyIsInN1YiI6Ik5TZ0tBY1BBZU82MG14YU5wQ091ZWpINjF2bUNuSzh4QGNsaWVudHMiLCJhdWQiOiJodHRwczovL2VkZS1yZXBvcnQtc2VydmljZSIsImlhdCI6MTY5NjUwNjE2MSwiZXhwIjoxNjk2NTkyNTYxLCJhenAiOiJOU2dLQWNQQWVPNjBteGFOcENPdWVqSDYxdm1Dbks4eCIsImd0eSI6ImNsaWVudC1jcmVkZW50aWFscyJ9.L0PCD1xgCQkWyRcajEFikyLSmQ08UWRpaxggQmJGfmn3GmFbHHe5Eu9sXzBOxsfAu4gFemD9rc98qOMU2Kp5LTqEeL4Bp9sg_davlQkEKeTv0FdfsMdmSOTR3cv57OvReDQbIpWDBZCPbIhV7FbrD5L4LMiHNCvXCgSZbzYGt_dZZEFQopo6kQ1erdtTu0ccrnWf4Lx2u_z8musCyDN2ta3J_XYUGPLEYsoZub8MYAzVwBOixulGBYSHDMMxezgbmW6RWqjUPxVwSG7EPPFI8byDWZpboFzCFkctVqht0xLIyjz0qrsm7WxeF0DQ3NEnGsvAY2iKERYgG6me2PIrpA'
EXPECTED_ISSUER = f'https://{AUTH0_DOMAIN}/'
# Function to retrieve the Auth0 JSON Web Key Set (JWKS)
def get_jwks():
    jwks_url = f'https://{AUTH0_DOMAIN}/.well-known/jwks.json'
    response = requests.get(jwks_url)
    jwks = response.json()
    return jwks

# Function to base64url decode a string
def base64url_decode(input):
    input += '=' * (4 - len(input) % 4)  # Add padding if needed
    return base64.urlsafe_b64decode(input)

# Function to validate the Auth0 token
def validate_token(token):
    jwks = get_jwks()

    for key in jwks['keys']:
        if key['kty'] == 'RSA' and key['alg'] == 'RS256':
            n = int.from_bytes(base64url_decode(key['n']), byteorder='big')
            e = int.from_bytes(base64url_decode(key['e']), byteorder='big')
            rsa_key = rsa.RSAPublicNumbers(e, n).public_key(default_backend())
            pem_key = rsa_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            )

            try:
                payload = jwt.decode(
                    token,
                    pem_key,
                    algorithms=['RS256'],
                    audience='https://ede-report-service',
                    issuer=EXPECTED_ISSUER,
                )
                if payload['iss'] != EXPECTED_ISSUER:
                    return 'Invalid issuer'
                
                # Check token expiration
                now = datetime.utcnow()
                if 'exp' in payload and now > datetime.utcfromtimestamp(payload['exp']):
                    return 'Token has expired'
                
                return 'Token is valid'
            except jwt.ExpiredSignatureError:
                return 'Token has expired'
            except jwt.InvalidAudienceError:
                return 'Invalid audience'
            except jwt.DecodeError:
                return 'Invalid token'
            except jwt.InvalidAlgorithmError:
                return 'Invalid algorithm'
    
    return 'RSA key with RS256 algorithm not found in JWKS'

if __name__ == "__main__":
    result = validate_token(TOKEN)
    print(result)
