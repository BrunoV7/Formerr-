from typing import List, Any
from sqlalchemy.ext.asyncio import AsyncSession

class FormsService:
    @staticmethod
    async def get_user_forms(db: AsyncSession, user_id: Any) -> List[Any]:
        # TODO: Implementar lógica real
        return []

class ResponsesService:
    @staticmethod
    async def get_form_responses(db: AsyncSession, form_id: Any, user_id: Any) -> List[Any]:
        # TODO: Implementar lógica real
        return [] 