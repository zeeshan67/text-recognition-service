import base64
import json
import boto3
from io import BytesIO
from PIL import Image
import pytesseract

# Initialize Textract client
textract = boto3.client('textract')


def handler(event, context):
    print(event)
    image_data = base64.b64decode(event['image'])
    image = Image.open(BytesIO(image_data))

    tesseract_text = pytesseract.image_to_string(image)

    textract_response = textract.analyze_document(
        Document={'Bytes': image_data},
        FeatureTypes=["TABLES", "FORMS"]
    )
    textract_text = extract_text_from_textract(textract_response)

    result_text = choose_higher_confidence(tesseract_text, textract_text)

    return {
        'statusCode': 200,
        'body': json.dumps({'detected_text': result_text})
    }


def extract_text_from_textract(response):
    text = ""
    for item in response.get('Blocks', []):
        if item['BlockType'] == 'LINE':
            text += item['Text'] + "\n"
    return text


def choose_higher_confidence(text1, text2):
    return text1 if len(text1) > len(text2) else text2
