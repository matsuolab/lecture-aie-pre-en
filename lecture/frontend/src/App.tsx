import { useState } from "react";

// nginx reverse-proxies /app/api to the backend container, so
// the frontend can send requests using a path relative to the origin serving it.
// (Hard-coding localhost would prevent access from other hosts, such as Codespace.)
const API_URL = "/app/api";

export function App() {
  const [inputText, setInputText] = useState("");
  const [result, setResult] = useState("");

  const handleSend = async () => {
    if (!inputText) return;

    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ input_text: inputText }),
      });

      if (!response.ok) {
        throw new Error("An API error occurred");
      }

      const data = await response.json();
      setResult(`Reply: ${data.reply}`);
    } catch (error) {
      console.error(error);
      setResult("Communication failed.");
    }
  };

  return (
    <>
      <h1>Docker Compose Demo</h1>
      <input
        type="text"
        placeholder="Enter a message"
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
      />
      <button onClick={handleSend}>Send</button>
      <p>{result}</p>
    </>
  );
}
