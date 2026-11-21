---
name: explain-diff
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Publishes it as a Claude Artifact.
---

# Explain Diff

Please make me a rich, interactive explanation of the specified code change.

It should have these sections:

- Background: Explain the existing system relevant to this change. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the change.
- Intuition: Explain the core intuition for the code change. The focus here is to explain the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
- Code: Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.
- Quiz: Come up with five questions that test the reader's knowledge of this PR. This should be medium difficulty, difficult enough that you actually need to understand the substance of the PR to answer them, but not gotchas. The goal is to help the reader make sure that they've actually understood. These should be presented as interactive multiple-choice questions, and when the user clicks, it tells them whether they were correct and gives feedback.

Format:

- Publish it as a Claude Artifact with the Artifact tool, following that tool's own setup steps (its quickstart and design guidance) before writing the page. Write the page as a single self-contained HTML file with inline CSS and JavaScript, in your scratchpad directory (or a temp directory if there is none), never inside the code repo. Make the whole thing one long page with section headers and a table of contents. Don't use tabs for the top-level structure. It should read well on a phone.
- Give the page a short `<title>` naming the change, and a one-sentence `description` on publish. When you're done, give me the artifact's link.
- If I ask for changes to an explanation you published in this conversation, republish from the same file path so the link stays the same.
- Please write with the clarity and flow of Martin Kleppmann, making it engaging and written in classic style. Transitions between sections should be smooth.
- Some tips on diagrams. Ideally, you should pick a small number of diagram families that can be reused throughout the explanation to explain various cases. Some useful kinds of diagrams:
  - A very simplified version of the UI that the user sees in the app, to explain UI changes.
  - A system diagram showing data flow or communication between components. Make sure to include example data here!
- Don't use ASCII diagrams. Always use simple HTML designs for your diagrams, HTML lists for lists of things, etc.
  - For code blocks, always use `<pre>` tags. If you use a custom styled div instead, it **must** have
    `white-space: pre-wrap` in its CSS, or the browser will collapse all newlines into a single line.
    Escape `&`, `<` and `>` inside code blocks, or generics like `Vec<T>` are parsed as HTML tags and vanish.
    Before publishing, scan each code block in the HTML source and confirm both.
- Use callouts for key concepts or definitions, important edge cases, etc.
