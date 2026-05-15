import google.generativeai as genai
import re

# ==========================================================
# GEMINI API KEYS
# ==========================================================

API_KEYS = [
    "AIzaSyDQI-Lybbh4OJj7L_dBXG6FjzwmhWEHbSo",
    "AIzaSyCTOSNfWEK9ZM0uafhPSMoXk3BiueWiC5c"
]

current_key_index = 0


def get_model():
    global current_key_index

    api_key = API_KEYS[current_key_index]

    genai.configure(api_key=api_key)

    return genai.GenerativeModel("gemini-2.5-flash")


def generate_with_fallback(content):

    global current_key_index

    for i in range(len(API_KEYS)):

        try:

            model = get_model()

            response = model.generate_content(content)

            return response.text

        except Exception as e:

            print("Gemini API failed with key:", API_KEYS[current_key_index])
            print("Error:", e)

            current_key_index += 1

            if current_key_index >= len(API_KEYS):
                current_key_index = 0

    return ""


# ==========================================================
# SKETCH DETECTION USING GEMINI
# ==========================================================

def check_sketch(image_path):

    try:

        with open(image_path, "rb") as f:
            img_bytes = f.read()

        content = [
            "Check this image. Is it a real human photograph or a sketch/drawing/cartoon? Reply only with PHOTO or SKETCH.",
            {"mime_type": "image/png", "data": img_bytes}
        ]

        result = generate_with_fallback(content)

        result = result.strip().upper()

        print("Gemini result:", result)

        if "SKETCH" in result:
            return True

        return False

    except Exception as e:

        print("Gemini error:", e)

        return False


# ==========================================================
# CLEAN AI TEXT
# ==========================================================

def clean_ai_text(text):

    if not text:
        return ""

    text = re.sub(r'[#*]', '', text)

    return text.strip()


# ==========================================================
# USER FINANCIAL REPORT
# ==========================================================

def generate_user_financial_report(total_income, total_expense):

    try:

        savings = float(total_income) - float(total_expense)

        prompt = f"""
Generate a clear monthly financial summary for a user.

Financial Data:
Monthly Income: ₹{total_income}
Monthly Expense: ₹{total_expense}
Monthly Savings: ₹{savings}

Explain clearly:

1. Income vs Expense overview
2. Monthly savings explanation
3. Spending behavior analysis
4. Suggestions to improve savings

Do not use markdown formatting like ** or ##.
"""

        response = generate_with_fallback(prompt)

        report = clean_ai_text(response)

        if not report:
            return "Financial report could not be generated."

        return report

    except Exception as e:

        print("Gemini USER report error:", e)

        return "Unable to generate financial summary at the moment."


# ==========================================================
# BANK LOAN REPORT
# ==========================================================
def generate_bank_loan_report(total_income, total_expense, prediction):

    try:

        total_income = float(total_income)
        total_expense = float(total_expense)

        savings = total_income - total_expense

        expense_ratio = (total_expense / total_income) * 100 if total_income else 0

        prompt = f"""
You are a senior credit risk analyst working for an Indian bank.

Evaluate the financial stability and loan eligibility of a customer.

Financial Data:
Monthly Income: ₹{total_income}
Monthly Expense: ₹{total_expense}
Monthly Savings: ₹{savings}
Expense Ratio: {expense_ratio:.2f}%
Model Prediction: {prediction}

Provide the report using this structure:

Income Stability:
Explain if the income appears stable and sufficient.

Expense Ratio:
Explain whether spending is low, moderate, or high.

Savings Capacity:
Explain the ability to maintain savings.

Loan Repayment Ability:
Explain ability to pay EMI.

Risk Level:
Low / Medium / High

Final Recommendation:
Eligible / Review / Not Eligible

Keep the report concise and professional.
Do not include customer name or date.
"""

        response = generate_with_fallback(prompt)

        report = response.strip()

        # Clean formatting
        report = report.replace("*", "").replace("#", "")
        report = report.replace("Customer Name:", "")
        report = report.replace("Date:", "")

        return report.strip()

    except Exception as e:

        print("Gemini BANK report error:", e)

        return "Loan analysis could not be generated."

# ==========================================================
# DOCUMENT SUMMARY
# ==========================================================

def generate_document_summary(document_text):

    try:

        if not document_text:
            return "Document text not available for analysis."

        document_text = document_text[:12000]

        prompt = f"""
You are an AI assistant specialized in summarizing insurance, claim,
medical, financial, and legal documents.

Analyze the document text and generate a structured summary.

Document Text:
{document_text}

You MUST return the summary using EXACTLY these sections:

Description:
Main Points:
Detailed Explanation:
Final Summary:

Rules:
- Description must be a short paragraph
- Main Points must contain bullet-style points
- Detailed Explanation must be a paragraph
- Final Summary must be a short paragraph
- Do not use markdown symbols like ** or ##
"""

        response = generate_with_fallback(prompt)

        report = response.strip()

        report = report.replace("*", "").replace("#", "")
        report = re.sub(r'\n+', '\n', report)

        if "Description:" not in report:
            report = "Description:\n" + report

        if "Main Points:" not in report:
            report += "\n\nMain Points:\n"

        if "Detailed Explanation:" not in report:
            report += "\n\nDetailed Explanation:\n"

        if "Final Summary:" not in report:
            report += "\n\nFinal Summary:\n"

        lines = report.split("\n")

        formatted = []
        section = ""

        for line in lines:

            line = line.strip()

            if not line:
                continue

            if ":" in line and len(line.split()) <= 3:
                section = line
                formatted.append("\n" + line)
                continue

            if section == "Main Points:":
                formatted.append("• " + line)
            else:
                formatted.append(line)

        return "\n".join(formatted).strip()

    except Exception as e:

        print("Gemini DOCUMENT summary error:", e)

        return "Document summary could not be generated."