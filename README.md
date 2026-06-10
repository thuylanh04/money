# 💰 Money Management Application

A personal finance management application that helps users track income and expenses, manage budgets, analyze spending habits, and improve financial planning through AI-powered features.

## ✨ Features

### 🔐 Authentication
- User registration with email verification
- Secure login and password recovery

### 💸 Transaction Management
- Record income and expenses
- Manage categories and accounts
- View transaction history
- Search and filter transactions

### 📊 Budget Management
- Create monthly budgets
- Monitor spending limits
- Receive budget alerts

### 📈 Reports & Analytics
- Financial overview dashboard
- Expense statistics by category
- Daily, weekly, monthly, and yearly reports
- Visual charts and summaries

### 🤖 AI-Powered Features
- Automatic expense categorization
- Smart saving recommendations
- Budget warning notifications
- Receipt scanning and data extraction

### 🧾 Receipt Processing
- OCR-based text extraction using EasyOCR
- Invoice classification using Google Gemini
- Automatic amount detection
- Auto-fill transaction information from receipts

---

## 🛠️ Tech Stack

### Frontend
- Flutter
- Dart

### Backend
- Java
- Spring Boot

### AI & OCR Service
- Python
- Flask
- EasyOCR
- Google Gemini API

### Database
- MySQL

### Tools
- VS Code
- Postman
- Figma
- Git

---

## 🏗️ System Architecture

```text
Flutter Mobile App
        │
        ▼
Spring Boot REST API
        │
 ┌──────┴──────┐
 ▼             ▼
MySQL      Python OCR Service
Database         │
                 ├── EasyOCR
                 └── Gemini API
````

---

## 📂 Main Modules

* Authentication
* Transaction Management
* Category Management
* Account Management
* Budget Management
* Financial Reports
* AI Expense Classification
* Receipt OCR Processing
* Smart Recommendations

---

## 🚀 Installation

### Backend

```bash
cd backend
mvn spring-boot:run
```

### AI Service

```bash
cd ai-service
pip install -r requirements.txt
python app.py
```

### Frontend

```bash
cd mobile
flutter pub get
flutter run
```

---

## 🔮 Future Improvements

* Bank API integration
* E-wallet synchronization
* Advanced AI financial assistant
* Family/shared budgeting
* Web and desktop versions
* Enhanced analytics and forecasting
```
```
