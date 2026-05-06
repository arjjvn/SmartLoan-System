import os
import json
import hashlib
from datetime import datetime
from web3 import Web3
from solcx import compile_source, install_solc


# =====================================================
# 🔹 Install Solidity Compiler (Only First Time)
# =====================================================
install_solc("0.8.0")


# =====================================================
# 🔹 Connect to Ganache
# =====================================================
ganache_url = "HTTP://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))

if not web3.is_connected():
    raise Exception("❌ Failed to connect to Ganache")

if len(web3.eth.accounts) == 0:
    raise Exception("❌ No accounts found in Ganache")

web3.eth.default_account = web3.eth.accounts[0]
print(f"✔ Using account: {web3.eth.default_account}")


# =====================================================
# 🔹 Paths
# =====================================================
BASE_DIR = os.path.dirname(__file__)
CONTRACT_DIR = os.path.join(BASE_DIR, "contract")
SOL_PATH = os.path.join(CONTRACT_DIR, "LoanRecord.sol")
DEPLOY_INFO_PATH = os.path.join(CONTRACT_DIR, "deployed.json")


# =====================================================
# 🔹 Compile & Deploy Contract
# =====================================================
def get_contract():

    if not os.path.exists(SOL_PATH):
        raise Exception("❌ LoanRecord.sol not found")

    with open(SOL_PATH, "r") as file:
        source_code = file.read()

    compiled_sol = compile_source(source_code, solc_version="0.8.0")
    contract_id = next(iter(compiled_sol))
    contract_interface = compiled_sol[contract_id]

    contract_needs_redeploy = True

    if os.path.exists(DEPLOY_INFO_PATH):
        sol_mtime = os.path.getmtime(SOL_PATH)
        deploy_mtime = os.path.getmtime(DEPLOY_INFO_PATH)
        if sol_mtime <= deploy_mtime:
            contract_needs_redeploy = False

    # 🔹 Load existing contract
    if os.path.exists(DEPLOY_INFO_PATH) and not contract_needs_redeploy:

        with open(DEPLOY_INFO_PATH, "r") as file:
            deploy_data = json.load(file)

        contract_address = deploy_data["address"]
        abi = deploy_data["abi"]

        contract = web3.eth.contract(address=contract_address, abi=abi)
        print(f"✔ Contract loaded (address: {contract_address})")

    # 🔹 Deploy new contract
    else:
        print("🚀 Deploying new LoanRecord contract...")

        Contract = web3.eth.contract(
            abi=contract_interface["abi"],
            bytecode=contract_interface["bin"]
        )

        tx_hash = Contract.constructor().transact({
            'from': web3.eth.default_account,
            'gas': 5000000
        })

        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

        contract_address = tx_receipt.contractAddress
        abi = contract_interface["abi"]

        with open(DEPLOY_INFO_PATH, "w") as file:
            json.dump({
                "address": contract_address,
                "abi": abi
            }, file, indent=2)

        contract = web3.eth.contract(address=contract_address, abi=abi)

        print(f"✅ Contract deployed at: {contract_address}")

    return contract


# Initialize Contract
contract = get_contract()


# =====================================================
# 🔹 Generate SHA256 Hash (Large File Safe)
# =====================================================
import hashlib

def generate_file_hash(file_obj):

    try:

        sha256 = hashlib.sha256()

        # If file has chunks() (UploadedFile)
        if hasattr(file_obj, "chunks"):

            for chunk in file_obj.chunks():
                sha256.update(chunk)

        else:
            # Normal file (BufferedReader)
            while True:
                chunk = file_obj.read(4096)
                if not chunk:
                    break
                sha256.update(chunk)

        return sha256.hexdigest()

    except Exception as e:
        print("❌ Hash error:", e)
        return ""

# =====================================================
# 🔹 Add Loan to Blockchain
# =====================================================
def addLoan(loan_id, user_id, bank_id, amount,
            doc_hash="", face_hash="", status="Pending"):

    try:
        # Convert Decimal safely
        amount_int = int(float(amount))

        tx_hash = contract.functions.addLoan(
            int(loan_id),
            int(user_id),
            int(bank_id),
            amount_int,
            doc_hash or "",
            face_hash or "",
            status,
            datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        ).transact({
            'from': web3.eth.default_account,
            'gas': 3000000
        })

        receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

        print(f"✅ Loan stored on blockchain (Loan ID: {loan_id})")

        return {
            "success": True,
            "tx_hash": tx_hash.hex(),
            "block_number": receipt.blockNumber,
            "contract_address": contract.address
        }

    except Exception as e:
        print(f"❌ Blockchain error: {e}")
        return {
            "success": False,
            "error": str(e)
        }


# =====================================================
# 🔹 Get Loan by Index
# =====================================================
def getLoan(index):

    try:
        result = contract.functions.getLoan(int(index)).call()

        loan_data = {
            "loanId": result[0],
            "userId": result[1],
            "bankId": result[2],
            "amount": result[3],
            "documentHash": result[4],
            "faceHash": result[5],
            "status": result[6],
            "date": result[7]
        }

        return {
            "success": True,
            "data": loan_data
        }

    except Exception as e:
        print(f"❌ GetLoan error: {e}")
        return {
            "success": False,
            "error": str(e)
        }


# =====================================================
# 🔹 Get Total Loan Count
# =====================================================
def getLoanCount():

    try:
        count = contract.functions.getLoanCount().call()

        return {
            "success": True,
            "count": int(count)
        }

    except Exception as e:
        print(f"❌ GetLoanCount error: {e}")
        return {
            "success": False,
            "error": str(e)
        }


# =====================================================
# 🔹 Verify Document Integrity
# =====================================================
def verify_document(index, uploaded_file):

    try:
        blockchain_data = getLoan(index)

        if not blockchain_data["success"]:
            return blockchain_data

        original_hash = blockchain_data["data"]["documentHash"]
        new_hash = generate_file_hash(uploaded_file)

        if original_hash == new_hash:
            return {
                "success": True,
                "verified": True,
                "message": "Document is authentic ✅"
            }
        else:
            return {
                "success": True,
                "verified": False,
                "message": "Document has been tampered ❌"
            }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }