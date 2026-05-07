"""
train_toxicity.py
-----------------
Run this ONCE before starting the Flask server.

Usage:
    python train_toxicity.py \
        --train  "/Users/muskanmanvi/Desktop/sentiment analysis/train(T).csv" \
        --test   "/Users/muskanmanvi/Desktop/sentiment analysis/test(T).csv" \
        --labels "/Users/muskanmanvi/Desktop/sentiment analysis/test_labels(T).csv"

Saves trained TF-IDF vectorizer + 6 LogisticRegression classifiers
(one per toxicity label) to  ./saved_models/
"""

import argparse, os, re, string, warnings
warnings.filterwarnings("ignore")

import pandas as pd
import joblib
from nltk.stem.wordnet import WordNetLemmatizer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import f1_score, recall_score

TOX_LABELS = ["toxic", "severe_toxic", "obscene", "threat", "insult", "identity_hate"]
SAVE_DIR   = os.path.join(os.path.dirname(__file__), "saved_models")


def tokenize(text: str):
    """Identical to the notebook's tokenize() function."""
    text    = text.lower()
    regex   = re.compile("[" + re.escape(string.punctuation) + r"0-9\r\t\n]")
    nopunct = regex.sub(" ", text)
    words   = nopunct.split(" ")
    words   = [w.encode("ascii", "ignore").decode("ascii") for w in words]
    lmtzr   = WordNetLemmatizer()
    words   = [lmtzr.lemmatize(w) for w in words]
    words   = [w for w in words if len(w) > 2]
    return words


def main(train_path: str, test_path: str, labels_path: str):
    os.makedirs(SAVE_DIR, exist_ok=True)

    print("📂  Loading datasets …")
    train   = pd.read_csv(train_path)
    test    = pd.read_csv(test_path)
    test_y  = pd.read_csv(labels_path)

    print(f"   Train rows : {len(train):,}")
    print(f"   Test  rows : {len(test):,}")

    # ── TF-IDF vectorizer (fit on train only) ────────────────────────────────
    print("\n🔧  Fitting TF-IDF vectorizer …")
    vectorizer = TfidfVectorizer(
        ngram_range=(1, 1),
        analyzer="word",
        tokenizer=tokenize,
        stop_words="english",
        strip_accents="unicode",
        use_idf=True,
        min_df=10,
    )
    X_train = vectorizer.fit_transform(train["comment_text"])
    X_test  = vectorizer.transform(test["comment_text"])
    print(f"   Vocabulary size: {len(vectorizer.vocabulary_):,}")

    joblib.dump(vectorizer, os.path.join(SAVE_DIR, "tfidf_vectorizer.joblib"))
    print("   Saved: tfidf_vectorizer.joblib")

    # ── One LogisticRegression per label ─────────────────────────────────────
    print("\n🤖  Training classifiers …")
    for label in TOX_LABELS:
        clf = LogisticRegression(max_iter=1000, C=1.0)
        clf.fit(X_train, train[label])

        # Evaluate on labeled test rows (label == -1 means unlabeled)
        mask      = test_y[label] != -1
        predicted = clf.predict(X_test[mask])
        true      = test_y[mask][label]

        f1  = f1_score(true, predicted, average="weighted")
        rec = recall_score(true, predicted, average="weighted")
        print(f"   [{label:>15}]  F1={f1:.3f}  Recall={rec:.3f}")

        path = os.path.join(SAVE_DIR, f"clf_{label}.joblib")
        joblib.dump(clf, path)

    print(f"\n✅  All models saved to  {SAVE_DIR}/")
    print("    You can now run:  python app.py")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--train",  required=True, help="Path to train(T).csv")
    parser.add_argument("--test",   required=True, help="Path to test(T).csv")
    parser.add_argument("--labels", required=True, help="Path to test_labels(T).csv")
    args = parser.parse_args()
    main(args.train, args.test, args.labels)