FROM public.ecr.aws/docker/library/python:3.11-slim

COPY ltr/sagemaker/requirements*.txt .

RUN python -m pip install --upgrade pip
RUN python -m pip install -U --no-cache-dir -r requirements-freeze.txt

COPY ltr/sagemaker/* .

CMD ["python3", "main.py"]
