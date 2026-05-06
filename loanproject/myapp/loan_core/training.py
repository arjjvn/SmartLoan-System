import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report


# -----------------------------
# File Paths
# -----------------------------
dataset_path = r"D:\project_trustify\loanproject\myapp\loan_core\loan_approval_dataset (1).csv"
model_path = r"D:\project_trustify\loanproject\myapp\loan_core\loan_model.pkl"
result_path = r"D:\project_trustify\loanproject\myapp\loan_core\result.txt"


# -----------------------------
# Load Dataset
# -----------------------------
df = pd.read_csv(dataset_path)

# Clean column names
df.columns = df.columns.str.strip()

print("Dataset Loaded Successfully")
print("Columns:", df.columns)


# -----------------------------
# Create Required Features
# -----------------------------

# Convert annual income → monthly income
df["total_income"] = df["income_annum"] / 12

# Estimate monthly expense (assume 60% spending)
df["total_expense"] = df["total_income"] * 0.6

# Savings
df["savings"] = df["total_income"] - df["total_expense"]

# Loan amount
df["loan_amount"] = df["loan_amount"]

# CIBIL score
df["cibil_score"] = df["cibil_score"]

# Interest rate (synthetic for training)
df["interest_rate"] = 10

# Duration
df["duration"] = df["loan_term"]


# -----------------------------
# Target Variable
# -----------------------------
df["loan_status"] = df["loan_status"].str.strip()

df["loan_status"] = df["loan_status"].map({
    "Approved": 1,
    "Rejected": 0
})

df = df.dropna(subset=["loan_status"])


# -----------------------------
# Features and Target
# -----------------------------
X = df[[
    "total_income",
    "total_expense",
    "savings",
    "loan_amount",
    "cibil_score",
    "interest_rate",
    "duration"
]]

y = df["loan_status"]

print("\nTraining Features:")
print(X.columns)


# -----------------------------
# Train Test Split
# -----------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42
)


# -----------------------------
# Train Model
# -----------------------------
model = RandomForestClassifier(
    n_estimators=200,
    random_state=42
)

model.fit(X_train, y_train)


# -----------------------------
# Prediction
# -----------------------------
y_pred = model.predict(X_test)


# -----------------------------
# Evaluation
# -----------------------------
accuracy = accuracy_score(y_test, y_pred)
report = classification_report(y_test, y_pred)

print("\nAccuracy:", accuracy)
print("\nClassification Report:\n", report)


# -----------------------------
# Save Model
# -----------------------------
joblib.dump(model, model_path)

print("\nModel saved at:", model_path)


# -----------------------------
# Save Results
# -----------------------------
with open(result_path, "w") as f:
    f.write("Loan Prediction Model Results\n\n")
    f.write("Accuracy: " + str(accuracy) + "\n\n")
    f.write("Classification Report:\n")
    f.write(report)

print("Results saved at:", result_path)