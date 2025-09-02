# DEBUG_MODE takes 0 or 1 as a value. 0 = False, 1 = True.
DEBUG_MODE=1
IIASA_MICROSOFT_OPENID_ISSUER_WELL_KNOWN_CONF='https://login.microsoftonline.com/9b79b10b-0007-4e8a-b072-asdfgcdc1aa5/v2.0/.well-known/openid-configuration'
BUCKET_DETAILS_ENCRYPTION_KEY='<mocked>'
JWT_BASE64_PRIVATE_KEY='<mocked>'
JWT_BASE64_PUBLIC_KEY='<mocked>'
ALLOWED_ORIGINS='["http://localhost:8080", "https://localhost:8080", "https://localhost:8081", "http://localhost:8008", "https://localhost:8008"]'

INITIAL_S3_ENDPOINT='https://147.125.54.66:9000'
INITIAL_S3_API_KEY='<MinIO Access Key>'
INITIAL_S3_SECRET_KEY='<MinIO Secret Key>'
INITIAL_S3_BUCKET_NAME='accelerator'
PYTHONASYNCIODEBUG=1
PYTHONDEVMODE=1
CELERY_BROKER_URL='amqp://user:password@rabbitmq:5672/accelerator-native-jobs'

SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=
ACCELERATOR_EMAIL=

FRONTEND_URL='https://localhost:8080'

JOB_SECRET_ENCRYPTION_KEY='<mocked>'

JOBSTORE_S3_ENDPOINT='https://localip:9000'
JOBSTORE_S3_API_KEY='<MinIO Access Key>'
JOBSTORE_S3_SECRET_KEY='<MinIO Secret Key>'
JOBSTORE_S3_BUCKET_NAME='jobstore'