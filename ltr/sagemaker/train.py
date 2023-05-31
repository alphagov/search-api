import sagemaker
import sys
import time

def train(s3_bucket, image, role, instance_count, instance_type):
    session = sagemaker.Session()

    model_name = f"{str(time.time())}"

    # train model
    estimator = sagemaker.estimator.Estimator(
        f"{image}:latest",
        role,
        instance_count,
        instance_type,
        output_path=f"s3://{s3_bucket}/model/{model_name}",
        sagemaker_session=session,
        disable_profiler=True
    )

    estimator.fit(
        inputs={
            "train": f"s3://{s3_bucket}/data/train.txt",
            "test": f"s3://{s3_bucket}/data/test.txt",
            "validate": f"s3://{s3_bucket}/data/validate.txt",
        }
    )

    return f"{model_name}/{estimator._current_job_name}"
