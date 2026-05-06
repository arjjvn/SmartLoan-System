from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    first_name = models.CharField(max_length=255)
    last_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20)
    email = models.EmailField()
    place = models.CharField(max_length=255)
    photo = models.FileField(upload_to='profile_photos/')


class Complaint(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    date = models.CharField(max_length=255)
    replied_date = models.CharField(max_length=255)
    reply = models.TextField(null=True, blank=True)
    status = models.CharField(max_length=50)


class Bank(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    branch = models.CharField(max_length=255)
    email = models.EmailField()
    phone = models.CharField(max_length=20)
    place = models.CharField(max_length=255)


class LoanType(models.Model):
    bank = models.ForeignKey(Bank, on_delete=models.CASCADE)
    loan_type_name = models.CharField(max_length=255)
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2)
    duration = models.IntegerField()  # months/years
    details = models.TextField()


class LoanRequest(models.Model):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    bank = models.ForeignKey(Bank, on_delete=models.CASCADE)
    loan_type = models.ForeignKey(LoanType, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=50)

    documents = models.FileField(upload_to='loan_documents/')

    face_image = models.ImageField(upload_to='face_images/', null=True, blank=True)

    submitted_date = models.DateTimeField(auto_now_add=True)
    face_status = models.CharField(max_length=20, default="Pending")

class Income(models.Model):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    source = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.CharField(max_length=255)


class Expense(models.Model):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    category = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.CharField(max_length=255)


class DocumentUpload(models.Model):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    file_name = models.FileField(upload_to='documents/')
    upload_date = models.DateTimeField(auto_now_add=True)
    ai_summary = models.TextField()


class Feedback(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    date = models.DateTimeField(auto_now_add=True)


class MonthlyReport(models.Model):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    month = models.CharField(max_length=20)
    total_income = models.DecimalField(max_digits=12, decimal_places=2)
    total_expense = models.DecimalField(max_digits=12, decimal_places=2)
    user_report = models.TextField()
    bank_report = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)