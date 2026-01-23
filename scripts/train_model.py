"""
Sample script to train and save a simple ML model
This is just for demonstration - replace with your actual model training logic
"""

import joblib
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split


def train_sample_model():
    """
    Train a simple Random Forest classifier for demonstration
    """
    # Generate sample data
    x, y = make_classification(
        n_samples=1000, n_features=10, n_informative=8, n_redundant=2, random_state=42
    )

    # Split data
    x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.2, random_state=42)

    # Train model
    print("Training Random Forest Classifier...")
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(x_train, y_train)

    # Evaluate
    train_score = model.score(x_train, y_train)
    test_score = model.score(x_test, y_test)

    print(f"Training accuracy: {train_score:.4f}")
    print(f"Test accuracy: {test_score:.4f}")

    # Save model
    model_path = "model.pkl"
    joblib.dump(model, model_path)
    print(f"Model saved to {model_path}")

    return model


if __name__ == "__main__":
    train_sample_model()
