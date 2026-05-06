"""
URL configuration for loanproject project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path


from myapp import views

urlpatterns = [
    path('',views.home,name='home'),
    path('login/',views.login,name='login'),
    path('logout_view/', views.logout_view, name='logout_view'),

    path('admin_home/', views.admin_home, name='admin_home'),
    path('admin_manage_bank', views.admin_manage_bank, name='admin_manage_bank'),
    path('admin_view_user', views.admin_view_user, name='admin_view_user'),
    path('admin_view_complaint', views.admin_view_complaint, name='admin_view_complaint'),
    path('admin_reply/<int:id>', views.admin_reply, name='admin_reply'),
    path('admin_view_feedback', views.admin_view_feedback, name='admin_view_feedback'),
    # ============== bank ======================================================================

    path('bank_home', views.bank_home, name='bank_home'),
    path('bank_loan_types', views.bank_loan_types, name='bank_loan_types'),
    path('loan_type_edit/<int:id>/', views.loan_type_edit, name='loan_type_edit'),
    path('delete_loan_type/<int:id>/', views.delete_loan_type, name='delete_loan_type'),

    path('user_loan_request', views.bank_view_loan_requests, name='user_loan_request'),
    path('bank_view_user_report/<int:loan_id>/', views.bank_view_user_report, name='bank_view_user_report'),
    path('bank_approve_loan/<int:loan_id>/', views.bank_approve_loan,name='bank_approve_loan'),
    path('bank_reject_loan/<int:loan_id>/', views.bank_reject_loan,name='bank_reject_loan'),
    path('bank_check_face/<int:id>/', views.bank_check_face, name='bank_check_face'),

    path('sent_complaint', views.sent_complaint, name='sent_complaint'),
    path('view_reply', views.view_reply, name='view_reply'),
    path('send_feedback', views.send_feedback, name='send_feedback'),

    # ============== user ======================================================================


    path('user_register/', views.user_register, name='user_register'),
    path('user_login/', views.user_login, name='user_login'),
    path('user_view_profile/', views.user_view_profile, name='user_view_profile'),
    path('user_edit_profile/', views.user_edit_profile, name='user_edit_profile'),

    path('user_Banks/', views.user_Banks, name='user_Banks'),
    path('loan_types_by_bank/', views.loan_types_by_bank, name='loan_types_by_bank'),
    path('user_send_loan_request/', views.user_send_loan_request, name='user_send_loan_request'),
    path('user_view_loan_request/', views.user_view_loan_request, name='user_view_loan_request'),

    path('user_manage_income/', views.user_manage_income, name='user_manage_income'),
    path('user_view_income/', views.user_view_income, name='user_view_income'),
    path('user_delete_income/', views.user_delete_income, name='user_delete_income'),
    path('user_manage_expense/', views.user_manage_expense, name='user_manage_expense'),
    path('user_view_expense/', views.user_view_expense, name='user_view_expense'),
    path('user_delete_expense/', views.user_delete_expense, name='user_delete_expense'),
    path('user_delete_expense/', views.user_delete_expense, name='user_delete_expense'),

    path('user_monthly_report/', views.user_monthly_report,name='user_monthly_report'),
    path('upload_document_ai_summary/', views.upload_document_ai_summary,name='upload_document_ai_summary'),
    path('view_document_ai_summary/', views.view_document_ai_summary,name='view_document_ai_summary'),
    path('list_user_documents/', views.list_user_documents, name='list_user_documents'),
    path('user_send_compaint/', views.user_send_compaint, name='user_send_compaint'),
    path('user_view_reply/', views.user_view_reply, name='user_view_reply'),
    path('user_send_feedback/', views.user_send_feedback, name='user_send_feedback'),
    path('user_view_feedback/', views.user_view_feedback, name='user_view_feedback'),

]
