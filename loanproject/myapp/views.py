import base64
import os
import uuid
from _pydatetime import datetime

from django.conf import settings
from django.contrib.auth import authenticate, login as auth_login, logout
from django.contrib.auth.decorators import login_required
from django.core.checks import messages
from django.http import JsonResponse
from django.shortcuts import render, redirect, get_object_or_404

# Create your views here.
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_exempt

from myapp.models import *


def home(request):
    return render(request,'public_home.html')


def login(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']

        user = authenticate(request, username=username, password=password)
        print(username,password)
        if user is not None:
            auth_login(request, user)
            request.session['user_id'] = user.id

            if user.groups.filter(name='admin').exists():
                return redirect('admin_home')

            elif user.groups.filter(name='banks').exists():
                bank= Bank.objects.get(user=user)
                print(bank)
                request.session['bank_id'] = bank.id
                return redirect('bank_home')


        else:
            messages.error(request, "invalid username or password")
            return redirect('login')

    return render(request,'public_login.html')



@login_required(login_url='login')
@never_cache
def logout_view(request):
    logout(request)
    request.session.flush()
    messages.success(request, "Logged out successfully.")
    return redirect('login')
# ============ admin =========================================
@login_required
@csrf_exempt
@never_cache
def admin_home(request):
    users = UserProfile.objects.all()
    banks = Bank.objects.all()
    loan_types = LoanType.objects.all()
    complaints = Complaint.objects.all()
    feedbacks = Feedback.objects.all().order_by('-date').select_related('user')


    context = {
        'users': users,
        'banks': banks,
        'loan_types': loan_types,
        'complaints': complaints,
        'feedbacks': feedbacks,
    }

    return render(request, 'admin_home.html', context)

from django.contrib.auth.models import User, Group
from django.contrib import messages
from django.shortcuts import render, redirect


@login_required
@csrf_exempt
@never_cache
def admin_manage_bank(request):
    banks=Bank.objects.all()
    if request.method == "POST":

        username = request.POST.get('username')
        password = request.POST.get('password')
        name = request.POST.get('name')
        branch = request.POST.get('branch')
        email = request.POST.get('email')
        phone = request.POST.get('phone')
        place = request.POST.get('place')

        if User.objects.filter(username=username).exists():
            messages.error(request, "Username already exists")
            return redirect('admin_manage_bank')

        user = User.objects.create_user(
            username=username,
            password=password,
            email=email
        )
        group=Group.objects.get(name='banks')
        user.groups.add(group)
        user.save()


        Bank.objects.create(
            user=user,
            name=name,
            branch=branch,
            email=email,
            phone=phone,
            place=place
        )

        messages.success(request, "Bank registered successfully!")
        return redirect('admin_manage_bank')

    return render(request, 'admin_manage_bank.html',{'b':banks})




@login_required
@csrf_exempt
@never_cache
def admin_view_user(request):
    user = UserProfile.objects.all()
    return render(request,'admin_view_user.html',{'U':user})



@login_required
@csrf_exempt
@never_cache
def admin_view_complaint(request):
    complaint = Complaint.objects.all()
    return render(request,'admin_view_complaint.html',{'C':complaint})




@login_required
@csrf_exempt
@never_cache
def admin_reply(request,id):
    complaint = Complaint.objects.get(id=id)
    if request.method=='POST':
        complaint.reply=request.POST['Reply']
        complaint.replied_date=datetime.today()
        complaint.status = 'Replied'
        complaint.save()
        return redirect('admin_view_complaint')
    return render(request,'admin_view_complaint.html',{'C':complaint})
def admin_view_feedback(request):
    feedback=Feedback.objects.all()
    return render(request,'admin_view_feedback.html',{'F':feedback})




# =============== bank ======================================================


from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import never_cache
from datetime import datetime
from .models import LoanType, Complaint, Feedback, User, Bank

@login_required
@csrf_exempt
@never_cache
def bank_home(request):
    bank_id = request.session.get('bank_id')
    user_id = request.session.get('user_id')

    # Loan types for the bank
    loan_types = LoanType.objects.filter(bank_id=bank_id)

    # Complaints for the bank
    not_seen_complaints = Complaint.objects.filter(status='pending')  # or 'Open'
    replied_complaints = Complaint.objects.filter(status='replied')
    total_complaints = Complaint.objects.all()

    # Recent feedback
    feedbacks = Feedback.objects.all().order_by('-date')[:5]  # latest 5

    context = {
        'loan_types': loan_types,
        'not_seen_complaints': not_seen_complaints,
        'replied_complaints': replied_complaints,
        'feedbacks': feedbacks,
        'total_feedback': Feedback.objects.count(),
        'total_loan_types': loan_types.count(),
        'total_not_seen_complaints': not_seen_complaints.count(),
        'total_replied_complaints': replied_complaints.count(),
        'total_complaints': total_complaints.count(),
    }

    return render(request, 'bank_home.html', context)



@login_required
@csrf_exempt
@never_cache
def bank_loan_types(request):

    bank = Bank.objects.get(id=request.session['bank_id'])

    if request.method == "POST":
        loan_type_name = request.POST.get('loan_type_name')
        interest_rate = request.POST.get('interest')
        duration = request.POST.get('duration')
        details = request.POST.get('details')

        LoanType.objects.create(
            bank=bank,
            loan_type_name=loan_type_name,
            interest_rate=interest_rate,
            duration=duration,
            details=details,
        )

        messages.success(request, "Loan Type registered successfully!")

    # Show only this bank loan types
    a = LoanType.objects.filter(bank=bank)

    return render(request, 'bank_loan_types.html', {'L': a})



def loan_type_edit(request, id):
    loan = get_object_or_404(LoanType, id=id)

    if request.method == "POST":
        loan.loan_type_name = request.POST.get('loan_type_name')
        loan.interest_rate = request.POST.get('interest')
        loan.duration = request.POST.get('duration')
        loan.details = request.POST.get('details')

        loan.save()

    return redirect('bank_loan_types')




@login_required
@never_cache
def delete_loan_type(request, id):

    bank = Bank.objects.get(id=request.session['bank_id'])

    loan = LoanType.objects.get(id=id)

    if loan.bank == bank:
        loan.delete()

    return redirect('bank_loan_types')


from .blockchain import getLoanCount, getLoan, generate_file_hash
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required
from .models import LoanRequest
from .detection import detect_face_image

@login_required(login_url='login')
@never_cache
@csrf_exempt
def bank_view_loan_requests(request):

    bank = Bank.objects.get(user=request.user)
    data = LoanRequest.objects.filter(bank=bank)
    count_response = getLoanCount()
    blockchain_data = {}

    if count_response["success"]:
        total = count_response["count"]

        for i in range(total):
            loan_response = getLoan(i)

            if loan_response["success"]:
                loan = loan_response["data"]
                blockchain_data[loan["loanId"]] = loan
    for d in data:

        if d.id in blockchain_data:

            bc = blockchain_data[d.id]

            if d.documents:
                with open(d.documents.path, 'rb') as f:
                    current_hash = generate_file_hash(f)

                if current_hash == bc["documentHash"]:
                    d.doc_verified = True
                else:
                    d.doc_verified = False
            else:
                d.doc_verified = False
        else:
            d.doc_verified = False

    return render(request,'bank_user_loan_request.html',{
        'data': data,
        'pending_count': data.filter(status='Pending').count(),
        'approved_count': data.filter(status='Approved').count(),
    })

@login_required(login_url='login')
def bank_check_face(request, id):

    print("🔥 Deepfake check called")

    bank = Bank.objects.get(user=request.user)

    loan = get_object_or_404(LoanRequest, id=id, bank=bank)

    print("Loan ID:", loan.id)

    if not loan.face_image:
        print("❌ No face image uploaded")

        return JsonResponse({
            "success": False,
            "error": "No face image uploaded"
        })

    print("Face image path:", loan.face_image.path)

    # Run AI detection
    result = detect_face_image(loan.face_image.path)

    print("Detection result:", result)

    if result["success"]:

        # ONLY UPDATE STATUS
        loan.face_status = result["status"]
        loan.save()

        print("✅ Face status saved:", result["status"])

        return JsonResponse({
            "success": True,
            "status": result["status"],
            "confidence": result["confidence"]
        })

    print("❌ Detection failed:", result["error"])

    return JsonResponse({
        "success": False,
        "error": result["error"]
    })



import joblib
import numpy as np
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.contrib.auth.decorators import login_required

from .models import Bank, LoanRequest, MonthlyReport
from .gemini_ai import generate_bank_loan_report


@login_required(login_url='login')
def bank_view_user_report(request, loan_id):

    if request.method == "POST":

        bank = Bank.objects.get(user=request.user)
        loan = get_object_or_404(LoanRequest, id=loan_id, bank=bank)

        user_profile = loan.user

        # Bank enters CIBIL score
        cibil_score = float(request.POST.get('cibil_score'))

        report = MonthlyReport.objects.filter(user=user_profile)\
            .order_by('-created_at')\
            .first()

        if not report:
            return JsonResponse({
                'status': 'error',
                'message': 'No financial report found'
            })

        # Financial values
        total_income = float(report.total_income)
        total_expense = float(report.total_expense)

        savings = total_income - total_expense

        loan_amount = float(loan.amount)

        # From LoanType
        interest_rate = float(loan.loan_type.interest_rate)
        duration = float(loan.loan_type.duration)

        # Load ML model
        model = joblib.load(
            r"D:\project_trustify\loanproject\myapp\loan_core\loan_model.pkl"
        )

        # Send exactly 7 features (same order as training)
        features = np.array([[
            total_income,
            total_expense,
            savings,
            loan_amount,
            cibil_score,
            interest_rate,
            duration
        ]])

        prediction = model.predict(features)[0]

        eligibility = "Eligible" if prediction == 1 else "Not Eligible"

        print("\n===== ML LOAN PREDICTION =====")
        print("Income:", total_income)
        print("Expense:", total_expense)
        print("Savings:", savings)
        print("Loan Amount:", loan_amount)
        print("CIBIL Score:", cibil_score)
        print("Interest Rate:", interest_rate)
        print("Duration:", duration)
        print("Prediction:", prediction)
        print("Eligibility:", eligibility)
        print("==============================\n")

        # Generate AI explanation
        ai_report = generate_bank_loan_report(
            total_income,
            total_expense,
            eligibility
        )

        return JsonResponse({
            'status': 'ok',

            'loan_prediction': eligibility,

            'monthly_income': total_income,
            'monthly_expense': total_expense,
            'monthly_savings': savings,

            'loan_amount': loan_amount,
            'cibil_score': cibil_score,
            'interest_rate': interest_rate,
            'duration': duration,

            'ai_report': ai_report
        })

    return JsonResponse({'status': 'error'})


@login_required(login_url='login')
def bank_approve_loan(request, loan_id):

    loan = LoanRequest.objects.get(id=loan_id)

    loan.status = "Approved"
    loan.save()

    return redirect('user_loan_request')


@login_required(login_url='login')
def bank_reject_loan(request, loan_id):

    loan = LoanRequest.objects.get(id=loan_id)

    loan.status = "Rejected"
    loan.save()

    return redirect('user_loan_request')







@login_required
@csrf_exempt
@never_cache
def sent_complaint(request):
    U=User.objects.get(id=request.session['user_id'])
    if request.method == "POST":
        complaint = request.POST.get('complaint')

        Complaint.objects.create(
            message=complaint,
            user=U,
            date=datetime.now().strftime('%d/%m/%Y %I:%M%p'),
            replied_date='pending',
            reply='pending',
            status='pending',
        )

    return render(request,'bank_sent_complaint.html')




@login_required
@csrf_exempt
@never_cache
def view_reply(request):
    complaint=Complaint.objects.filter(user=request.session['user_id'])

    return render(request,'bank_view_reply.html',{'complaint':complaint})



@login_required
@csrf_exempt
@never_cache
def send_feedback(request):
    C = User.objects.get(id=request.session['user_id'])
    if request.method == "POST":
        feedback = request.POST.get('Feedback')

        Feedback.objects.create(
            message=feedback,
            user=C,
            date=datetime.now().strftime('%d/%m/%Y %I:%M%p')
        )
    return render(request,'bank_send_feedback.html')

# ---------------------------------------------- USER -------------------------------------------------------------------------------

import os
import uuid
import base64
from datetime import datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
from django.contrib.auth.models import User, Group
from django.contrib.auth import authenticate
from .models import UserProfile



# --------------------------------------------------------
# USER REGISTER
# --------------------------------------------------------

@csrf_exempt
def user_register(request):

    if request.method == 'POST':

        firstname = request.POST.get('firstname')
        lastname = request.POST.get('lastname')
        email = request.POST.get('email')
        phone = request.POST.get('phone')
        place = request.POST.get('place')
        username = request.POST.get('username')
        password = request.POST.get('password')
        photo = request.FILES.get('photo')


        if not all([firstname, lastname, email, phone, place, username, password, photo]):
            return JsonResponse({'status':'error'})


        if User.objects.filter(username=username).exists():
            return JsonResponse({'status':'exist'})


        user = User.objects.create_user(username=username,password=password)


        group,created = Group.objects.get_or_create(name='user')
        user.groups.add(group)
        user.save()


        obj = UserProfile()

        obj.user = user
        obj.first_name = firstname
        obj.last_name = lastname
        obj.phone = phone
        obj.email = email
        obj.place = place
        obj.photo = photo

        obj.save()


        return JsonResponse({'status':'ok'})


    return JsonResponse({'status':'no'})


def user_login(request):
    username = request.POST['username']
    password = request.POST['password']

    user = authenticate(request, username=username, password=password)

    if user is not None:
        auth_login(request, user)


        if user.groups.filter(name='user').exists():
            return JsonResponse({'status': 'ok', 'lid': str(user.id)})


        else:
            return JsonResponse({'status': 'error'})


    else:
        return JsonResponse({'status': 'error'})




@csrf_exempt
def user_view_profile(request):

    lid = request.POST.get('lid')

    user = User.objects.get(id=lid)
    profile = UserProfile.objects.get(user=user)

    if profile.photo:
        photo_url = request.build_absolute_uri(profile.photo.url)
    else:
        photo_url = ""

    return JsonResponse({
        'status': 'ok',
        'firstname': profile.first_name,
        'lastname': profile.last_name,
        'email': profile.email,
        'phone': profile.phone,
        'place': profile.place,
        'photo': photo_url
    })


@csrf_exempt
def user_edit_profile(request):

    if request.method == "POST":

        lid = request.POST.get('lid')
        firstname = request.POST.get('firstname')
        lastname = request.POST.get('lastname')
        email = request.POST.get('email')
        phone = request.POST.get('phone')
        place = request.POST.get('place')
        photo = request.FILES.get('photo')

        user = User.objects.get(id=lid)
        profile = UserProfile.objects.get(user=user)

        profile.firstname = firstname
        profile.lastname = lastname
        profile.email = email
        profile.phone = phone
        profile.place = place

        if photo:
            profile.photo = photo

        profile.save()

        return JsonResponse({'status':'ok'})

    return JsonResponse({'status':'no'})



def user_Banks(request):

    banks = Bank.objects.all()

    bank_list = []

    for bank in banks:

        bank_list.append({

            'id': bank.id,
            'name': bank.name,
            'branch': bank.branch,
            'email': bank.email,
            'phone': bank.phone,
            'place': bank.place,

        })

    return JsonResponse({

        'status': 'ok',
        'data': bank_list

    })




from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import LoanType


@csrf_exempt
def loan_types_by_bank(request):

    bank_id = request.POST.get('bank_id')

    loans = LoanType.objects.filter(bank_id=bank_id)

    data = []

    for i in loans:

        data.append({

            'id': i.id,
            'loan_type_name': i.loan_type_name,
            'interest_rate': i.interest_rate,
            'duration': i.duration,
            'details': i.details

        })

    return JsonResponse({
        'status':'ok',
        'data':data
    })



# @csrf_exempt
# def user_send_loan_request(request):
#
#     if request.method == "POST":
#
#         lid = request.POST.get('lid')
#         loan_id = request.POST.get('loan_id')
#         amount = request.POST.get('amount')
#
#         document = request.FILES.get('documents')
#         face_image = request.FILES.get('face_image')
#
#         user = User.objects.get(id=lid)
#         profile = UserProfile.objects.get(user=user)
#
#         loan = LoanType.objects.get(id=loan_id)
#
#         LoanRequest.objects.create(
#
#             user=profile,
#             bank=loan.bank,
#             loan_type=loan,
#             amount=amount,
#             status="Pending",
#
#             documents=document,
#             face_image=face_image,
#
#         )
#
#         return JsonResponse({'status':'ok'})
#
#     return JsonResponse({'status':'error'})


from .blockchain import addLoan, generate_file_hash

@csrf_exempt
def user_send_loan_request(request):

    print("🔥 View called")

    if request.method == "POST":

        try:
            print("➡ POST request received")

            lid = request.POST.get('lid')
            loan_id = request.POST.get('loan_id')
            amount = request.POST.get('amount')

            print("User ID:", lid)
            print("Loan ID:", loan_id)
            print("Amount:", amount)

            document = request.FILES.get('documents')
            face_image = request.FILES.get('face_image')

            print("Document:", document)
            print("Face Image:", face_image)

            user = User.objects.get(id=lid)
            profile = UserProfile.objects.get(user=user)
            loan = LoanType.objects.get(id=loan_id)

            print("User object:", user)
            print("Profile:", profile)
            print("Loan:", loan)

            # ✅ 1️⃣ Save in Database
            loan_request = LoanRequest.objects.create(
                user=profile,
                bank=loan.bank,
                loan_type=loan,
                amount=amount,
                status="Pending",
                documents=document,
                face_image=face_image,
            )

            print("✅ Saved in DB. LoanRequest ID:", loan_request.id)

            # ✅ 2️⃣ Generate Hashes
            doc_hash = generate_file_hash(document) if document else ""
            face_hash = generate_file_hash(face_image) if face_image else ""

            print("Document Hash:", doc_hash)
            print("Face Hash:", face_hash)

            # ✅ 3️⃣ Store in Blockchain
            print("🚀 Calling addLoan()")

            blockchain_response = addLoan(
                loan_request.id,
                profile.id,
                loan.bank.id,
                amount,
                doc_hash,
                face_hash,
                "Pending"
            )

            print("Blockchain Response:", blockchain_response)

            if not blockchain_response["success"]:
                print("❌ Blockchain failed")
                return JsonResponse({
                    'status': 'blockchain_error',
                    'error': blockchain_response["error"]
                })

            print("✅ Blockchain Success!")

            return JsonResponse({
                'status': 'ok',
                'tx_hash': blockchain_response["tx_hash"],
                'block_number': blockchain_response["block_number"]
            })

        except Exception as e:
            print("❌ Exception occurred:", str(e))
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    print("❌ Invalid request method")
    return JsonResponse({'status': 'invalid_request'})


@csrf_exempt
def user_view_loan_request(request):

    lid = request.POST.get('lid')

    user = User.objects.get(id=lid)

    profile = UserProfile.objects.get(user=user)

    data = LoanRequest.objects.filter(user=profile)

    loan_list = []

    for i in data:

        loan_list.append({

            'id': i.id,
            'bank': i.bank.name,
            'loan_type': i.loan_type.loan_type_name,
            'amount': str(i.amount),
            'status': i.status,
            'date': str(i.submitted_date),

            'document': str(i.documents),
            'face_image': str(i.face_image),

        })

    return JsonResponse({

        'status':'ok',
        'data':loan_list

    })

@csrf_exempt
def user_manage_income(request):

    if request.method == "POST":

        lid = request.POST.get('lid')

        user = User.objects.get(id=lid)

        profile = UserProfile.objects.get(user=user)

        source = request.POST.get('source')
        amount = request.POST.get('amount')
        date = request.POST.get('date')

        if not all([source, amount, date]):

            return JsonResponse({
                'status':'error',
                'message':'Missing fields'
            })

        Income.objects.create(

            user=profile,
            source=source,
            amount=amount,
            date=date

        )

        return JsonResponse({

            'status':'ok',
            'message':'Saved Successfully'

        })

    return JsonResponse({

        'status':'error'

    })


@csrf_exempt
def user_view_income(request):

    lid = request.POST.get('lid')

    user = User.objects.get(id=lid)
    profile = UserProfile.objects.get(user=user)

    data = Income.objects.filter(user=profile)

    income_list = []

    for i in data:

        income_list.append({

            'id': i.id,
            'source': i.source,
            'amount': i.amount,
            'date': i.date

        })

    return JsonResponse({

        'status':'ok',
        'data':income_list

    })



@csrf_exempt
def user_delete_income(request):

    id = request.POST.get('id')

    Income.objects.filter(id=id).delete()

    return JsonResponse({

        'status':'ok'

    })


# ==================================================

@csrf_exempt
def user_manage_expense(request):

    if request.method == "POST":

        lid = request.POST.get('lid')

        user = User.objects.get(id=lid)

        profile = UserProfile.objects.get(user=user)

        category = request.POST.get('category')
        amount = request.POST.get('amount')
        date = request.POST.get('date')

        if not all([category, amount, date]):

            return JsonResponse({
                'status':'error',
                'message':'Missing fields'
            })

        Expense.objects.create(

            user=profile,
            category=category,
            amount=amount,
            date=date

        )

        return JsonResponse({

            'status':'ok',
            'message':'Saved Successfully'

        })

    return JsonResponse({'status':'error'})

@csrf_exempt
def user_view_expense(request):

    lid = request.POST.get('lid')

    print("LID =", lid)

    user_obj = User.objects.get(id=lid)
    profile = UserProfile.objects.get(user=user_obj)

    expenses = Expense.objects.filter(user=profile)

    print("Expense Count =", expenses.count())

    data = []

    for i in expenses:
        data.append({
            'id': i.id,
            'category': i.category,
            'amount': str(i.amount),
            'date': i.date
        })

    return JsonResponse({
        'status': 'ok',
        'data': data
    })

def user_delete_expense(request):
    if request.method == "POST":
        expense_id = request.POST.get('expense_id')
        obj = Expense.objects.get(id=expense_id)
        obj.delete()
        return JsonResponse({'status': 'ok'})
    return JsonResponse({'status': 'error'})





from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from django.db.models import Sum
from django.utils import timezone
from django.shortcuts import get_object_or_404

from .models import Income, Expense, UserProfile, MonthlyReport
from .gemini_ai import generate_user_financial_report, generate_bank_loan_report

@csrf_exempt
def user_monthly_report(request):

    if request.method == "POST":

        lid = request.POST.get('lid')

        user = get_object_or_404(User, id=lid)
        profile = get_object_or_404(UserProfile, user=user)

        incomes = Income.objects.filter(user=profile)
        expenses = Expense.objects.filter(user=profile)

        total_income = incomes.aggregate(Sum('amount'))['amount__sum'] or 0
        total_expense = expenses.aggregate(Sum('amount'))['amount__sum'] or 0

        savings = float(total_income) - float(total_expense)

        # Generate ONLY user AI report
        user_ai_report = generate_user_financial_report(total_income, total_expense)

        month = timezone.now().strftime("%B %Y")

        MonthlyReport.objects.update_or_create(
            user=profile,
            month=month,
            defaults={
                "total_income": total_income,
                "total_expense": total_expense,
                "user_report": user_ai_report
            }
        )

        return JsonResponse({
            'status': 'ok',
            'total_income': float(total_income),
            'total_expense': float(total_expense),
            'savings': float(savings),
            'report': user_ai_report
        })

    return JsonResponse({'status': 'error'})





from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User

from .models import DocumentUpload, UserProfile
from .document_extractor import extract_text
from .gemini_ai import generate_document_summary


@csrf_exempt
def upload_document_ai_summary(request):

    if request.method == "POST":

        lid = request.POST.get("lid")
        file = request.FILES.get("document")

        user = User.objects.get(id=lid)
        profile = UserProfile.objects.get(user=user)

        doc = DocumentUpload.objects.create(
            user=profile,
            file_name=file
        )

        file_path = doc.file_name.path
        text = extract_text(file_path)
        summary = generate_document_summary(text)

        doc.ai_summary = summary
        doc.save()

        return JsonResponse({
            "status": "ok",
            "summary": summary
        })

    return JsonResponse({"status": "error"})


@csrf_exempt
def list_user_documents(request):

    if request.method == "POST":

        lid = request.POST.get("lid")

        user = User.objects.get(id=lid)
        profile = UserProfile.objects.get(user=user)
        docs = DocumentUpload.objects.filter(user=profile).order_by('-upload_date')

        data = []
        for d in docs:
            data.append({
                "id": d.id,
                "file_name": d.file_name.name.split('/')[-1],
                "uploaded_at": d.upload_date.strftime("%d %b %Y, %I:%M %p"),
            })

        return JsonResponse({"status": "ok", "documents": data})

    return JsonResponse({"status": "error"})


@csrf_exempt
def view_document_ai_summary(request):

    if request.method == "POST":

        doc_id = request.POST.get("doc_id")

        doc = DocumentUpload.objects.get(id=doc_id)

        return JsonResponse({
            "status": "ok",
            "file": doc.file_name.url,
            "summary": doc.ai_summary,
            "file_name": doc.file_name.name.split('/')[-1],
            "uploaded_at": doc.upload_date.strftime("%d %b %Y, %I:%M %p"),
        })

    return JsonResponse({"status": "error"})



# ======================================================


def user_send_compaint(request):
    if request.method == "POST":
            lid = request.POST['lid']
            b = User.objects.get(id=lid)
            message = request.POST.get('complaint')

            print(b)


            if not ([message]):
                return JsonResponse({'status': 'error', 'message': 'Missing fields'})

            # Save profile
            obj = Complaint()
            obj.user = b
            obj.message = message
            obj.date = datetime.now().strftime('%d/%m/%Y %I:%M%p')
            obj.replied_date= 'pending'
            obj.reply= 'pending'
            obj.status= 'pending'
            obj.save()
            print('ok')

            return JsonResponse({'status': 'ok','message':'Send successfully'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=400)


def user_view_reply(request):
    if request.method == "POST":
        lid = request.POST['lid']
        print(lid)
        try:
            b = User.objects.get(id=lid)
        except User.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'User not found'})

        complaint = Complaint.objects.filter(user=b)
        complaint_list = []

        for complaints in complaint:
            complaint_list.append({
                'user': complaints.user.id,
                'message': complaints.message,
                'date': complaints.date,
                'replied_date': complaints.replied_date,
                'reply': complaints.reply,
                'status': complaints.status,
            })

        return JsonResponse({
            'status': 'ok',
            'data': complaint_list
        })


def user_send_feedback(request):
    if request.method == "POST":
            lid = request.POST['lid']
            b = User.objects.get(id=lid)
            feedback = request.POST.get('message')

            print(b)


            if not ([feedback]):
                return JsonResponse({'status': 'error', 'message': 'Missing fields'})

            # Save profile
            obj = Feedback()
            obj.user = b
            obj.message = feedback
            obj.date=datetime.now().strftime('%d/%m/%Y %I:%M%p')
            obj.save()
            print('ok')

            return JsonResponse({'status': 'ok','message':'Send successfully'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=400)


def user_view_feedback(request):

    lid = request.POST.get('lid')

    b = User.objects.get(id=lid)

    feedback = Feedback.objects.filter(user=b)

    data = []

    for i in feedback:
        data.append({
            'id': i.id,
            'message': i.message,
            'date': i.date
        })

    return JsonResponse({'status':'ok','data':data})
# -------------------------------------------LOGOUT-----------------------------------------------------------------

