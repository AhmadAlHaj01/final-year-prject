# final-year-prject

This repository contains the codebase for the Final Year Project, which includes two branches:

Backend: Developed using Python.
Frontend: Built using Flutter.

Branches Overview
1. Backend Branch
The backend is implemented in Python and includes:

REST APIs for the project.
A requirements.txt file that lists all the dependencies needed to run the backend.

How to Set Up the Backend
Clone the repository and switch to the backend branch:

git clone https://github.com/AhmadAlHaj01/final-year-prject.git
cd final-year-prject
git checkout backend

Create and activate a Python virtual environment:

python -m venv venv
source venv/bin/activate    # On Windows: venv\Scripts\activate
Install the required dependencies:

pip install -r requirements.txt
Run the backend server:

python app.py  

2. Frontend Branch
The frontend is developed using Flutter and serves as the user interface for the project.

How to Set Up the Frontend
Clone the repository and switch to the frontend branch:
git clone https://github.com/AhmadAlHaj01/final-year-prject.git
cd final-year-prject
git checkout flutter_frontend
Ensure Flutter is installed. If not, follow the installation guide from Flutter's official documentation.
Run the project using the following commands:

flutter pub get
flutter run

Project Structure
Backend Branch:
requirements.txt: Contains Python dependencies.
Python files for the backend server and APIs.
Frontend Branch:
Flutter codebase, including lib/ for Dart files.
pubspec.yaml for managing Flutter dependencies
