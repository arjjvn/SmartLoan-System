// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoanRecord {

    struct Loan {
        uint loanId;
        uint userId;
        uint bankId;
        uint amount;
        string documentHash;
        string faceHash;
        string status;
        string date;
    }

    Loan[] public loans;

    function addLoan(
        uint loanId,
        uint userId,
        uint bankId,
        uint amount,
        string memory documentHash,
        string memory faceHash,
        string memory status,
        string memory date
    ) public {

        loans.push(Loan(
            loanId,
            userId,
            bankId,
            amount,
            documentHash,
            faceHash,
            status,
            date
        ));
    }

    function getLoan(uint index) public view returns (
        uint,
        uint,
        uint,
        uint,
        string memory,
        string memory,
        string memory,
        string memory
    ) {

        require(index < loans.length, "Invalid index");

        Loan storage loan = loans[index];

        return (
            loan.loanId,
            loan.userId,
            loan.bankId,
            loan.amount,
            loan.documentHash,
            loan.faceHash,
            loan.status,
            loan.date
        );
    }

    function getLoanCount() public view returns (uint) {
        return loans.length;
    }
}