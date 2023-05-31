FROM public.ecr.aws/docker/library/python:3.11-slim

COPY ltr/sagemaker/requirements*.txt .

RUN pip3 install -U --no-cache-dir -r requirements-freeze.txt

COPY ltr/sagemaker/* .

CMD ["python3", "main.py"]
