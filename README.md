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

    cd terraform
    terraform init
    terraform apply
   
    ```

Create separate tesseract Lambda layer for performing OCR from the below link
   ```bash 
   github.com/bweigel/aws-lambda-tesseract-layer```

   
To test the functionality use the invoke_script.py in the scripts folder

