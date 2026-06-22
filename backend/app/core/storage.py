import logging
from typing import Annotated

import aioboto3
from fastapi import Depends

from app.core.settings import settings

logger = logging.getLogger(__name__)


class StorageService:
    def __init__(self):
        self.session = aioboto3.Session()
        self.endpoint_url = settings.S3_ENDPOINT_URL
        self.access_key = settings.S3_ACCESS_KEY
        self.secret_key = settings.S3_SECRET_KEY
        self.bucket = settings.S3_BUCKET
        self.region = settings.S3_REGION

    async def _ensure_bucket(self, s3_client):
        try:
            await s3_client.head_bucket(Bucket=self.bucket)
        except Exception:
            logger.info(f"Criando bucket {self.bucket}...")
            await s3_client.create_bucket(Bucket=self.bucket)

    async def upload_file(
        self, file_content: bytes, filename: str, content_type: str
    ) -> str:
        async with self.session.client(
            "s3",
            endpoint_url=self.endpoint_url,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            region_name=self.region,
        ) as s3:
            await self._ensure_bucket(s3)
            await s3.put_object(
                Bucket=self.bucket,
                Key=filename,
                Body=file_content,
                ContentType=content_type,
            )
            # Retorna o path relativo que será salvo no banco
            return f"{self.bucket}/{filename}"

    async def get_download_url(self, file_path: str, expires_in: int = 3600) -> str:
        """Gera uma URL assinada para download temporário."""
        if not file_path:
            return ""

        # O file_path no banco está como 'bucket/filename'
        parts = file_path.split("/", 1)
        if len(parts) < 2:
            return ""

        bucket, key = parts

        async with self.session.client(
            "s3",
            endpoint_url=self.endpoint_url,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            region_name=self.region,
        ) as s3:
            return await s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": bucket, "Key": key},
                ExpiresIn=expires_in,
            )


def get_storage_service() -> StorageService:
    return StorageService()


StorageServiceDep = Annotated[StorageService, Depends(get_storage_service)]
