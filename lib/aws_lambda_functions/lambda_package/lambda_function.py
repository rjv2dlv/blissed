import os
import json
import boto3
import requests
import random
from datetime import datetime
from google.oauth2 import service_account
import google.auth.transport.requests
import pytz

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


# --- Helper Functions for Dynamic Reminders ---

PENDING_MESSAGES = [
    "Still pending: '{}'. Knock it off your list now!",
    "Quick nudge – remember to: '{}'",
    "Make today productive. Try finishing: '{}'",
    "You've got this! Just tackle: '{}'",
    "Still on your plate: '{}'. Let’s get it done!"
]

REFLECTION_MESSAGES = [
    "A little self-reflection goes a long way. What are you feeling today?",
    "Pause. Reflect. Write it down. Your thoughts matter.",
    "Jot down your self-reflection for today — it's like a mirror for the mind.",
    "Don’t forget your daily reflection. Let your thoughts breathe!",
    "Self-reflection time! Make space for your inner voice."
]

REFLECTION_PROMPT_MAP = {
    'who_do_you_want_to_be': "Who do you want to be today?",
    'how_will_you_connect': "How will you connect with people today?",
    'what_will_make_day_amazing': "What can you do to make your day amazing?",
    'two_changes_to_show_up': "2 simple changes for how you show up?"
}


def lambda_handler(event, context):
    print("Scheduler Lambda started")
    service_account_file = get_service_account_file()
    now_utc = datetime.utcnow().replace(tzinfo=pytz.utc)

    users = users_table.scan().get('Items', [])
    print(f"Found {len(users)} users.")

    for user in users:
        user_id = user['user_id']
        fcm_token = user.get('fcm_token')
        reminder_times = user.get('reminder_times', [])
        timezone = user.get('timezone', 'UTC')

        if not fcm_token or not reminder_times or not timezone:
            continue

        try:
            user_tz = pytz.timezone(timezone)
        except Exception as e:
            print(f"Invalid timezone for user {user_id}: {timezone}. Error: {e}")
            continue

        now_local = now_utc.astimezone(user_tz)
        current_local_time = now_local.strftime('%H:%M')
        today_local = now_local.strftime('%Y-%m-%d')

        if current_local_time not in reminder_times:
            continue

        print(f"Processing user: {user_id} at {current_local_time} ({timezone})")

        # Fetch user-specific data
        actions_resp = actions_table.get_item(Key={'user_id': user_id, 'date': today_local})
        actions = actions_resp.get('Item', {}).get('actions', [])
        pending = [a for a in actions if a['status'] == 'pending']

        reflection_resp = reflections_table.get_item(Key={'user_id': user_id, 'date': today_local})
        reflection_data = reflection_resp.get('Item')

        gratitude_resp = gratitude_table.get_item(Key={'user_id': user_id, 'date': today_local})
        gratitude_data = gratitude_resp.get('Item')

        # Define available notification handlers
        notification_handlers = {}

        if pending:
            def handle_pending():
                action = random.choice(pending)
                msg_template = random.choice(PENDING_MESSAGES)
                send_fcm_v1(
                    fcm_token,
                    "Pending Task Reminder",
                    msg_template.format(action['text']),
                    service_account_file
                )
            notification_handlers['pending'] = handle_pending

        if not reflection_data:
            def handle_missing_reflection():
                send_fcm_v1(
                    fcm_token,
                    "Time to Reflect",
                    random.choice(REFLECTION_MESSAGES),
                    service_account_file
                )
            notification_handlers['missing_reflection'] = handle_missing_reflection

        if reflection_data:
            def handle_existing_reflection():
                possible_keys = list(REFLECTION_PROMPT_MAP.keys())
                random.shuffle(possible_keys)
                for key in possible_keys:
                    answer = reflection_data.get(key)
                    if answer:
                        question = REFLECTION_PROMPT_MAP[key]
                        send_fcm_v1(
                            fcm_token,
                            "Your Reflection Today",
                            f"{question} — You said: \"{answer}\"",
                            service_account_file
                        )
                        break
            notification_handlers['existing_reflection'] = handle_existing_reflection

        if not gratitude_data:
            def handle_missing_gratitude():
                send_fcm_v1(
                    fcm_token,
                    "Gratitude Reminder",
                    "Add something you're grateful for today — even the little things count!",
                    service_account_file
                )
            notification_handlers['missing_gratitude'] = handle_missing_gratitude

        # Pick and execute one handler at random
        if notification_handlers:
            selected_key = random.choice(list(notification_handlers.keys()))
            print(f"Sending '{selected_key}' notification for user: {user_id}")
            notification_handlers[selected_key]()

    print("Scheduler Lambda finished")
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Notifications sent.'})
    }