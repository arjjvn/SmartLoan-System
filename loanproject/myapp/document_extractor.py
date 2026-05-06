import PyPDF2
import pytesseract
from PIL import Image
import re


def extract_text(file_path):

    text = ""

    if file_path.lower().endswith(".pdf"):
        try:
            with open(file_path, 'rb') as f:
                reader = PyPDF2.PdfReader(f)

                for page in reader.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"

        except Exception as e:
            print("PDF read error:", e)

    else:
        try:
            img = Image.open(file_path)
            text = pytesseract.image_to_string(img)

        except Exception as e:
            print("OCR error:", e)
            text = ""

    text = clean_document_text(text)

    return text


def clean_document_text(text):

    text = re.sub(r'\s+', ' ', text)
    text = text.replace("*", "").replace("#", "")

    # limit large documents for AI
    return text[:12000]