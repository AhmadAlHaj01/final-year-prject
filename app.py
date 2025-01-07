import spacy
from textstat import flesch_reading_ease, gunning_fog
from transformers import pipeline
from collections import Counter
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import logging
from nltk.corpus import wordnet 

logging.basicConfig(level=logging.DEBUG)

# Load SpaCy model and sentiment analysis pipeline
nlp = spacy.load("en_core_web_sm")
sentiment_analysis = pipeline("sentiment-analysis")

app = FastAPI()

class ContentEnhancer:
    def __init__(self, content, target_audience="public"):
        self.content = content
        self.target_audience = target_audience
        self.doc = nlp(content)

    def readability_scores(self):
        """Calculate readability scores."""
        flesch_score = flesch_reading_ease(self.content)
        fog_index = gunning_fog(self.content)
        return {
            "flesch_reading_ease": flesch_score,
            "gunning_fog_index": fog_index
        }

    def sentiment_analysis(self):
        """Determine overall sentiment."""
        sentiment = sentiment_analysis(self.content)
        return sentiment

    def simplify_sentences(self):
        """Provide recommendations to simplify complex sentences."""
        recommendations = []
        for sent in self.doc.sents:
            complex_words = [token.text for token in sent if token.is_alpha and len(token) > 10]
            if complex_words:
                recommendations.append({
                    "sentence": sent.text,
                    "complex_words": complex_words,
                    "recommendation": "Consider simplifying or breaking this sentence."
                })
        return recommendations

    def suggest_alternatives(self):
        """Provide alternative phrasings or synonyms using WordNet."""
        synonyms = {}
        for token in self.doc:
            if token.pos_ in {"ADJ", "VERB", "NOUN"}:  # Check for relevant parts of speech
                word_synonyms = set()
                for syn in wordnet.synsets(token.text):
                    for lemma in syn.lemmas():
                        if lemma.name() != token.text:
                            word_synonyms.add(lemma.name().replace('_', ' '))
                if word_synonyms:
                    synonyms[token.text] = list(word_synonyms)[:5]  # Limit to 5 alternatives
        return synonyms

    def identify_jargon(self):
        """Identify jargon or technical terms."""
        jargon = [ent.text for ent in self.doc.ents if ent.label_ in {"ORG", "TECH", "SCI"}]
        return jargon

    def keyword_recommendations(self):
        """Recommend keywords for search engine visibility."""
        word_freq = Counter([token.text.lower() for token in self.doc if token.is_alpha])
        return dict(word_freq.most_common(10))

    def concise_suggestions(self):
        """Recommend ways to make content concise."""
        recommendations = []
        for sent in self.doc.sents:
            if len(sent.text.split()) > 20:
                recommendations.append({
                    "sentence": sent.text,
                    "recommendation": "Consider rephrasing to make it shorter."
                })
        return recommendations

    def glossary_builder(self):
        """Assist in creating a glossary of technical terms."""
        glossary = {}
        jargon_terms = self.identify_jargon()
        for term in jargon_terms:
            glossary[term] = "Definition placeholder (could use APIs for definitions)"
        return glossary

    def overall_analysis(self):
        """Perform overall content analysis and suggestions."""
        return {
            "readability": self.readability_scores(),
            "sentiment": self.sentiment_analysis(),
            "simplification": self.simplify_sentences(),
            "alternatives": self.suggest_alternatives(),
            "jargon": self.identify_jargon(),
            "keywords": self.keyword_recommendations(),
            "conciseness": self.concise_suggestions(),
            "glossary": self.glossary_builder()
        }

@app.post("/chat")
async def chat_handler(request: Request):
    try:
        body = await request.json()
        logging.debug(f"Request Body: {body}")
        content = body.get("message", "")
        if not content:
            logging.error("No content provided in the request.")
            return JSONResponse(content={"error": "No content provided."}, status_code=400)

        enhancer = ContentEnhancer(content)
        logging.debug("ContentEnhancer initialized successfully.")
        analysis = enhancer.overall_analysis()
        logging.debug(f"Analysis Result: {analysis}")
        return JSONResponse(content={"response": analysis})

    except Exception as e:
        logging.error(f"Exception occurred: {e}")
        return JSONResponse(
            content={"error": f"An error occurred: {e}"},
            status_code=500
        )
