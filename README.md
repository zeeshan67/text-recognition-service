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
   
   1. **Create a new directory for your Docker setup**:
      ```bash
      mkdir tesseract
      cd tesseract
   
   2. **Create a Docker file**
   
         # Use Amazon Linux 2 x86 as the base image
      FROM public.ecr.aws/amazonlinux/amazonlinux:2
      
      # Install dependencies
      RUN yum install -y \
      epel-release \
      tesseract \
      && yum clean all
      
      # Create a directory for the layer
      RUN mkdir -p /opt/bin
      
      # Copy Tesseract binary to the layer directory
      RUN cp /usr/bin/tesseract /opt/bin/
      
      # Set the entrypoint
      ENTRYPOINT ["/opt/bin/tesseract"]

   3. **Build the docker image** 
      docker build -t tesseract .

   4. **Create a Container from the Image** 
      docker run --name tesseract-container -d tesseract
   
   5. ** Copy the Binary **
      docker cp tesseract-container:/opt/bin /path/to/your/tesseract_layer

   6. **cd /path/to/your/tesseract_layer**
      zip -r tesseract_layer.zip bin

    cd terraform
    terraform init
    terraform apply

   docker stop tesseract-container
   docker rm tesseract-container


    ```

   
To test the functionality use the invoke_script.py in the scripts folder

