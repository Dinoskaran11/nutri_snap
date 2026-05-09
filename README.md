NutriSnap - AI Food Scanner & Nutrition Tracker 🚀

NutriSnap is a Flutter mobile app designed for fitness enthusiasts and health-conscious individuals. Simply scan any food packet's ingredients label, and get instant nutritional analysis, calorie breakdown, healthier alternatives, and personalized dietary suggestions powered by AI!

✨ Key Features
📸 Smart Scanning
Camera-based ingredient scanning using Google ML Kit OCR

Extracts text from food labels instantly

Works with any packaged food product

🥗 AI-Powered Nutrition Analysis
Gemini AI API analyzes ingredients and calculates:

Calories per serving

Protein, Carbs, Fats breakdown

Full nutritional profile

Open Food Facts API integration for verified product data

💡 Healthier Alternatives
AI suggests better food swaps based on your scan

Promotes balanced nutrition and fitness goals

Dietary insights tailored to your preferences

🤖 NutriBot - AI Chat Assistant
Chat with your personal nutrition coach

Ask questions like: "What's a low-carb alternative for pasta?"

Real-time fitness and nutrition advice

📊 Beautiful Data Visualization
Card-based UI with clear nutrition breakdowns

Nutrient icons for protein, carbs, fats

Smooth animations and intuitive navigation

🌟 Daily Nutrition Tips
Fresh AI-generated health tips every day

Motivational content for your fitness journey



🚀 Quick Start
Prerequisites
Flutter SDK 3.x

Android/iOS development environment

API Keys (Gemini/ChatGPT)

Setup
bash
# Clone the repo
git clone https://github.com/yourusername/nutrisnap.git
cd nutrisnap

# Install dependencies
flutter pub get

# Configure API keys
# 1. Create .env file in root:
GEMINI_API_KEY=AIzaSyChFxuGn6D5ODyBW0EWQOOYj2YpW0h7kC8
OPENAI_API_KEY=your_openai_key_here

# 2. Update lib/services/api_service.dart with your keys

# Run the app
flutter run
