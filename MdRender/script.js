document.addEventListener("DOMContentLoaded", function () {
  const githubUserName = 'Ayanmullick';
  marked.use({ break: true });

  function renderFileContent(markdownFileUrl) {
    renderMarkDownFile(markdownFileUrl);
  }

  async function renderMarkDownFile(fileUrl) {
    return fetch(fileUrl).then(response => response.text()).then(markdown => {
      const contentIncludesInfo = [], regexPattern = `\\[(.*)\\].+\\(% include(.+)%\\)`, regex = new RegExp(regexPattern, "g");
      let groupIndex = 0;
      markdown = markdown.replaceAll(regex, (...groups) => {
        groupIndex++;
        const title = groups[1], path = groups[2].trim(), blockId = path.replace('.md', '') + groupIndex;
        contentIncludesInfo.push({ filePath: path, blockId: blockId });
        return `<details open id="${blockId}"><summary><strong><u>${title}</u></strong></summary></details>`;
      });

      document.getElementById("content").innerHTML = marked.parse(markdown);
      document.querySelectorAll("#content script").forEach(scriptTag => {
        if (scriptTag.src) {
          const externalScript = document.createElement("script");
          externalScript.src = scriptTag.src;
          document.getElementById("content").removeChild(scriptTag);
          document.getElementById("content").appendChild(externalScript);
        } else {
          eval(scriptTag.innerText);
        }
      });

      document.querySelectorAll("a").forEach(link => link.setAttribute("target", "_blank"));
      return contentIncludesInfo;
    }).then(contentIncludesInfo => {
      contentIncludesInfo.forEach(async includeInfo => {
        const baseIncludesPath = `https://raw.githubusercontent.com/${githubUserName}/AzIaaS/refs/heads/main/_includes/`;
        const fileContent = await getMarkdownFileContent(baseIncludesPath + includeInfo.filePath);
        document.getElementById(includeInfo.blockId).innerHTML += marked.parse(fileContent);
      });
    });
  }

  const urlParams = new URLSearchParams(window.location.search), path = urlParams.get("path");
  if (path !== "" && path !== null) renderFileContent(path);
});

var findBlocks = function (data, variableNames) {
  const matches = [];
  variableNames.forEach(function (variable) {
    const regexPattern = `#region(?<variableName> ${variable})(?<content>[\\s\\S]*?)(#endregion)`;
    let regex = new RegExp(regexPattern, "g");
    for (const match of data.matchAll(regex)) {
      const variableName = match.groups.variableName.trim();
      if (variableNames.includes(variableName)) {
        matches.push({ variableName, content: match.groups.content.trim() });
      }
    }
  });
  return matches;
};

function showBlocks(data, variableNames) {
  findBlocks(data, variableNames).forEach((item, index) => {
    let variableNameBlock = document.getElementById(item.variableName), codeBlock = document.getElementById("code" + index);
    if (codeBlock !== null) {
      codeBlock.textContent = item.content;
      hljs.highlightElement(codeBlock);
    }
    if (variableNameBlock !== null) variableNameBlock.textContent = item.variableName;
  });
}

function handleDocumentWrite(content) {
  document.getElementById("content").innerHTML += content;
}
window.document.write = handleDocumentWrite;

async function getMarkdownFileContent(markdownFileUrl) {
  return fetch(markdownFileUrl).then(response => response.text());
}