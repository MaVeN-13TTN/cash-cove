import pytest
from channels.testing import WebsocketCommunicator
from django.contrib.auth import get_user_model
from channels.layers import get_channel_layer
from asgiref.sync import sync_to_async
from core.asgi import application
import uuid

User = get_user_model()

@pytest.mark.asyncio
async def test_websocket_notifications():
    # Create a test user with a unique username
    unique_username = f'testuser_{uuid.uuid4()}'
    user = await sync_to_async(User.objects.create_user)(username=unique_username, password='password')

    # Create a communicator for the WebSocket
    communicator = WebsocketCommunicator(application, f'/ws/notifications/')
    communicator.scope['user'] = user

    # Connect to the WebSocket
    connected, _ = await communicator.connect()
    assert connected

    # Send a message to the channel layer asynchronously
    channel_layer = get_channel_layer()
    await channel_layer.group_send(
        f'user_{user.id}_notifications',
        {
            'type': 'notification_message',
            'message': 'Test notification'
        }
    )

    # Receive the message from the WebSocket
    response = await communicator.receive_json_from()
    assert response['message'] == 'Test notification'

    # Disconnect the WebSocket
    await communicator.disconnect()
