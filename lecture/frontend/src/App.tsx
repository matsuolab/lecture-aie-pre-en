import { useState } from "react";

// nginxが/app/apiをbackendコンテナへリバースプロキシするので、
// フロントは自分がアクセスされているオリジンへの相対パスでリクエストすればよい
// (localhostをハードコードするとCodespaceなど別ホストからのアクセスで届かなくなる)
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
        throw new Error("APIエラーが発生しました");
      }

      const data = await response.json();
      setResult(`返答: ${data.reply}`);
    } catch (error) {
      console.error(error);
      setResult("通信に失敗しました。");
    }
  };

  return (
    <>
      <h1>Docker Compose Demo</h1>
      <input
        type="text"
        placeholder="メッセージを入力"
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
      />
      <button onClick={handleSend}>送信</button>
      <p>{result}</p>
    </>
  );
}
