import requests
import base64

# Path to your image
image_path = 'sample_image.jpg'

# Convert the image to base64
with open(image_path, "rb") as image_file:
    encoded_string = base64.b64encode(image_file.read()).decode('utf-8')

API_GATEWAY_ENDPOINT = ""

# Define the API endpoint
url = f"{API_GATEWAY_ENDPOINT}/recognize"

# Create the payload
payload = {
    "image": encoded_string
}

# Send the POST request
response = requests.post(url, json=payload)

# Print the response
print(response.status_code)
print(response.json())
