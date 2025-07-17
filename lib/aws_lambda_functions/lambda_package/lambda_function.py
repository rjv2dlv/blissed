import os
import json
import boto3
import requests
from datetime import datetime
from google.oauth2 import service_account
import google.auth.transport.requests
import pytz  # <-- Make sure this is in your Lambda package

SECRET_NAME = 'fcm-service-account-json'
PROJECT_ID = 'blissed-28e44'

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table('Users')
actions_table = dynamodb.Table('Actions')
reflections_table = dynamodb.Table('Reflections')
gratitude_table = dynamodb.Table('Gratitude')

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
    print("Scheduler Lambda started")
    service_account_file = get_service_account_file()
    now_utc = datetime.utcnow().replace(tzinfo=pytz.utc)

    # 1. Scan all users
    users = users_table.scan().get('Items', [])
    print(f"Found {len(users)} users.")

    for user in users:
        user_id = user['user_id']
        fcm_token = user.get('fcm_token')
        reminder_times = user.get('reminder_times', [])
        timezone = user.get('timezone', 'UTC')
        if not fcm_token or not reminder_times or not timezone:
            continue

        # Convert current UTC time to user's local time zone
        try:
            user_tz = pytz.timezone(timezone)
        except Exception as e:
            print(f"Invalid timezone for user {user_id}: {timezone}. Error: {e}")
            continue

        now_local = now_utc.astimezone(user_tz)
        current_local_time = now_local.strftime('%H:%M')
        today_local = now_local.strftime('%Y-%m-%d')

        # Check if current local time matches any reminder time
        if current_local_time not in reminder_times:
            continue

        print(f"Processing user: {user_id} at {current_local_time} ({timezone})")

        # 2. Check for pending actions
        actions_resp = actions_table.get_item(Key={'user_id': user_id, 'date': today_local})
        actions = actions_resp.get('Item', {}).get('actions', [])
        pending = [a for a in actions if a['status'] == 'pending']

        if pending:
            action = pending[0]
            send_fcm_v1(fcm_token, "Complete your pending task!", f"Don't forget: {action['text']}", service_account_file)
            continue

        # 3. Check for missing reflection
        reflection_resp = reflections_table.get_item(Key={'user_id': user_id, 'date': today_local})
        if 'Item' not in reflection_resp:
            send_fcm_v1(fcm_token, "Reflection Reminder", "Don't forget to complete your self-reflection today!", service_account_file)
            continue

        # 4. Check for missing gratitude
        gratitude_resp = gratitude_table.get_item(Key={'user_id': user_id, 'date': today_local})
        if 'Item' not in gratitude_resp:
            send_fcm_v1(fcm_token, "Gratitude Reminder", "Add something you're grateful for today!", service_account_file)
            continue

    print("Scheduler Lambda finished")
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Notifications sent.'})
    }