import json
import requests
import jwt
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import base64
from datetime import datetime

def lambda_handler(event, context):
    # Retrieve the token from the event
    token = event['authorizationToken']
    #print(payload['sub'])
    print (event['methodArn'])
    # Your Auth0 domain and expected issuer
    AUTH0_DOMAIN = 'study-service.uk.auth0.com'
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
                        print("1")
                        return generate_policy('user', 'Deny', event['methodArn'])
                    
                    # Check token expiration
                    now = datetime.utcnow()
                    if 'exp' in payload and now > datetime.utcfromtimestamp(payload['exp']):
                        print("2")
                        return generate_policy('user', 'Deny', event['methodArn'])

                    # Token is valid
                    ##### authorizer test response #######
                    return generate_policy(payload['sub'], 'Allow', event['methodArn'])
                    ########################################
                except jwt.ExpiredSignatureError:
                    print("4")
                    return generate_policy('user', 'Deny', event['methodArn'])
                except jwt.InvalidAudienceError:
                    print("5")
                    return generate_policy('user', 'Deny', event['methodArn'])
                except jwt.DecodeError:
                    print("6")
                    return generate_policy('user', 'Deny', event['methodArn'])
                except jwt.InvalidAlgorithmError:
                    print("7")
                    return generate_policy('user', 'Deny', event['methodArn'])
        print("8")
        return generate_policy('user', 'Deny', event['methodArn'])

    # Function to generate an IAM policy
        # Function to generate an IAM policy with multiple HTTP methods
    def generate_policy(principal_id, effect, resource):
        auth_response = {
            'principalId': principal_id,
            'policyDocument': {
                'Version': '2012-10-17',
                'Statement': [
                    {
                        'Action': 'execute-api:Invoke',
                        'Effect': effect,
                        'Resource': event['methodArn']
                    }
                ]
            }
        }
        return auth_response


    return validate_token(token)
