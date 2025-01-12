document.addEventListener("DOMContentLoaded", function () {
  marked.use({ break: true });

  function renderFileContent(markdownFileUrl) {
    renderMarkDownFile(markdownFileUrl);
  }

  async function renderMarkDownFile(fileUrl) {
    return fetch(fileUrl)
      .then((response) => response.text())
      .then((markdown) => {
        const fileIncludesPaths = [];

        const regexPattern = `{%.+include(.+)%}`;
        let regex = new RegExp(regexPattern, "g");
        markdown = markdown.replaceAll(regex, function (...groups) {
          const path = groups[1].trim();
          fileIncludesPaths.push(path);
          return `<details open id="${path.replace('.md','')}">
            <summary>${path}</summary> 
            </details>`;
        });

        document.getElementById("content").innerHTML = marked.parse(markdown);
        var scriptTags = document.querySelectorAll("#content script");

        try {
          scriptTags.forEach(function (scriptTag) {
            if (scriptTag.src) {
              var externalScript = document.createElement("script");
              externalScript.src = scriptTag.src;
              document.getElementById("content").removeChild(scriptTag);
              document.getElementById("content").appendChild(externalScript);
            } else {
              eval(scriptTag.innerText);
            }
          });
        } catch (error) {
          console.log(error);
        }
        let links = document.querySelectorAll("a");
        for (let i = 0; i < links.length; i++) {
          links[i].setAttribute("target", "_blank");
        }
        return fileIncludesPaths;
      }).then((fileIncludesPaths) => {
        fileIncludesPaths.forEach(async (path) => {
          const baseIncludesFolderPath = 'https://raw.githubusercontent.com/amirKacem/AzIaaS/refs/heads/main/_includes/';
          const fileContent = await getMarkdownFileContent(baseIncludesFolderPath + path);
          document.getElementById(path.replace('.md','')).innerHTML += marked.parse(fileContent);
        });
      });
  }


  const urlParams = new URLSearchParams(window.location.search);
  const path = urlParams.get("path");
  if (path !== "" && path !== null) {
    renderFileContent(path);
  } 

});

var findBlocks = function (data, variableNames) {
  const matches = [];
  variableNames.forEach(function (variable) {
    const regexPattern = `#region(?<variableName> ${variable})(?<content>[\\s\\S]*?)(#endregion)`;
    let regex = new RegExp(regexPattern, "g");
    for (const match of data.matchAll(regex)) {
      const variableName = match.groups.variableName.trim();
      if (variableNames.includes(variableName)) {
        const content = match.groups.content.trim();

        matches.push({
          variableName,
          content,
        });
      }
    }
  });
  return matches;
};
function showBlocks(data, variableNames) {
  var blocks = findBlocks(data, variableNames);
  blocks.forEach(function (item, index) {
    let variableNameBlock = document.getElementById(item.variableName);
    let codeBlock = document.getElementById("code" + index);
    if (codeBlock !== null) {
      codeBlock.textContent = item.content;
      hljs.highlightElement(codeBlock);
    }
    if (variableNameBlock !== null) {
      variableNameBlock.textContent = item.variableName;
    }
  });
}

function handleDocumentWrite(content) {
  var contentPlaceholder = document.getElementById("content");
  contentPlaceholder.innerHTML += content}
  window.document.write = handleDocumentWrite;

async function getMarkdownFileContent(markdownFileUrl) {
  return fetch(markdownFileUrl).then(response => response.text());
}