import os
import json
import boto3
import requests
from google.oauth2 import service_account
import google.auth.transport.requests

# Name of your secret in AWS Secrets Manager
SECRET_NAME = 'fcm-service-account-json'
# Your Firebase project ID (from Firebase Console)
PROJECT_ID = 'blissed-28e44'  # e.g. blissed-123456

def get_service_account_file(secret_name=SECRET_NAME):
    client = boto3.client('secretsmanager')
    secret = client.get_secret_value(SecretId=secret_name)
    secret_json = secret['SecretString']
    path = '/tmp/service-account.json'
    with open(path, 'w') as f:
        f.write(secret_json)
    return path

def get_access_token(service_account_file):
    credentials = service_account.Credentials.from_service_account_file(
        service_account_file,
        scopes=['https://www.googleapis.com/auth/firebase.messaging']
    )
    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    return credentials.token

def send_fcm_v1(token, title, body, service_account_file):
    access_token = get_access_token(service_account_file)
    url = f'https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send'
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json; UTF-8',
    }
    message = {
        "message": {
            "token": token,
            "notification": {
                "title": title,
                "body": body
            }
        }
    }
    response = requests.post(url, headers=headers, data=json.dumps(message))
    print(response.status_code, response.text)
    return response

def lambda_handler(event, context):
    print("Event received:", event)
    user_fcm_token = event.get('fcm_token', 'user-fcm-token-here')
    notification_title = event.get('title', 'Hello from Lambda!')
    notification_body = event.get('body', 'This is a test notification.')
    print("Sending notification to:", user_fcm_token)
    # Call send_fcm_v1 and capture the response
    response = send_fcm_v1(user_fcm_token, notification_title, notification_body, get_service_account_file())
    print("Notification response:", response.text)
    return {
        'statusCode': 200,
        'body': json.dumps({'result': response.text})
    }