

# Text Recognition Service on AWS Lambda

## Overview

This project deploys a Text Recognition service using AWS Lambda. The service accepts base64 encoded images and returns detected text as a string. The implementation includes two distinct methodologies for text recognition and compares their effectiveness to choose the highest-confidence result.


## Requirements

- AWS account
- Python 3.11+
- Terraform
- AWS CLI configured with necessary permissions
- Virtual environment (optional)

## Setup Instructions

1. **Clone the Repository**

   ```bash
   git clone https://github.com/your_username/text-recognition-service.git
   cd text-recognition-service


    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   
    pip install -r app/handlers/requirements.txt -t app/handlers/python/
   
    # Tesseract OCR AWS Lambda Layer

   This instructions are for creating an AWS Lambda layer with Tesseract OCR, enabling the use of Tesseract in your Lambda functions.
   
   ## Prerequisites
   
     - Docker installed on your machine
     - AWS CLI configured with appropriate permissions
     - An AWS account
   
   ## Step 1: Create a Dockerfile for Tesseract
   
   1. **Create a new directory for your Dockerfile setup**:
      ```bash
      mkdir tesseract_layer
      cd tesseract_layer
   
   2. **Build the docker image** 
      cd docker
      docker build -t tesseract .

   4. **Create a Container from the Image** 
      docker run --name tesseract-container -d tesseract
   
   5. ** Copy the Binary **
      docker cp tesseract-container:/opt/build-dist tesseract_layer

   6. **cd /path/to/your/tesseract_layer**
      zip -r tesseract_layer.zip tesseract_layer

    cd terraform
    terraform init
    terraform apply

   docker stop tesseract-container
   docker rm tesseract-container


    ```

   
To test the functionality use the invoke_script.py in the scripts folder

