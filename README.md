# 💰 DueMate

> **A personal finance management application built to help users manage their money, expenses, bills, EMIs, loans, and financial activities in one place.**

---

## 📱 About DueMate

DueMate is a personal finance management application developed to make everyday money management simpler and more organized.

The application allows users to track their income and expenses, manage bills and EMIs, record borrowed and lent money, organize transactions, and view financial reports from a single platform.

The project is built as a full-stack mobile application using **Flutter, Node.js, Express.js, and MySQL**.

---

## ✨ Features

### 🏠 Dashboard
- Financial overview
- Recent transactions
- Upcoming payments
- Bills and EMI information
- Debt overview

### 💸 Transactions
- Add income
- Add expenses
- Edit transactions
- Delete transactions
- Categorize transactions
- View transaction history

### 📅 Calendar
- View financial activities by date
- Track upcoming financial events

### 💳 Bills & Payments
- Add bills
- Track payment information
- Manage upcoming payments

### 🏦 EMIs & Loans
- Add loans
- Manage EMI details
- Track EMI payments
- View loan information

### 🤝 Borrow & Lend
- Track borrowed money
- Track money lent to others
- Manage outstanding amounts

### 📂 Categories
- Create categories
- Edit categories
- Delete categories
- Organize transactions

### 📊 Reports
- View financial summaries
- Analyze income and expenses
- Understand spending patterns

### 📝 Notes
- Create personal financial notes
- Edit and delete notes

### 🔔 Notifications
- Financial reminders
- Important payment notifications

### 👤 Profile & Account
- Manage profile information
- Update account details
- Change passcode

### 🔐 Authentication
- Phone number login
- 6-digit passcode
- User registration
- Forgot passcode
- Change passcode
- Secure passcode handling

---

## 🛠️ Technology Stack

### Mobile Application

- **Flutter**
- **Dart**

### Backend

- **Node.js**
- **Express.js**
- **REST API**

### Database

- **MySQL**

### Development Tools

- Git
- GitHub
- Android Studio
- Visual Studio Code

---

## 🏗️ Application Architecture

```text
┌─────────────────────────┐
│      Flutter App        │
│       (Frontend)        │
└────────────┬────────────┘
             │
             │ REST API
             ▼
┌─────────────────────────┐
│    Node.js + Express    │
│        Backend          │
└────────────┬────────────┘
             │
             │ SQL Queries
             ▼
┌─────────────────────────┐
│       MySQL             │
│       Database          │
└─────────────────────────┘
