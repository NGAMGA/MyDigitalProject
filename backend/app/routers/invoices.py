import time
import uuid
from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user
from app.serializers import serialize_invoice

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.get("/me", response_model=list[schemas.InvoicePublic])
def list_my_invoices(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[schemas.InvoicePublic]:
    invoices = db.execute(
        select(models.Invoice)
        .where(models.Invoice.user_id == current_user.id)
        .order_by(desc(models.Invoice.issue_date), desc(models.Invoice.created_at))
    ).scalars().all()
    return [serialize_invoice(invoice) for invoice in invoices]


@router.post("/me/demo", response_model=schemas.InvoicePublic)
def create_demo_invoice(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.InvoicePublic:
    invoice = models.Invoice(
        id=str(uuid.uuid4()),
        reference=f"FAC-{str(int(time.time() * 1000))[-8:]}",
        user_id=current_user.id,
        issue_date=date.today(),
        label="Facture test Komi",
        amount_cents=499,
        status="Payee",
    )
    db.add(invoice)
    db.commit()
    db.refresh(invoice)
    return serialize_invoice(invoice)
