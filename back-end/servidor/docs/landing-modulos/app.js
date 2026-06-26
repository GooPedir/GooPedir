const areaData = [
  {
    name: "Atendimento",
    icon: "P",
    color: "#d9634f",
    text: "Pedidos, mesas, novo pedido e venda direta conectados ao caixa e impressao."
  },
  {
    name: "Financeiro",
    icon: "R",
    color: "#c58a2f",
    text: "Caixa, relatorios, resultados e dashboards para acompanhar operacao e venda."
  },
  {
    name: "Gestao",
    icon: "G",
    color: "#326b9a",
    text: "Despesas, fiado, auditoria, horario, parametros e cadastros administrativos."
  },
  {
    name: "Fiscal",
    icon: "F",
    color: "#177f7a",
    text: "NFC-e, DF-e, NF-e entrada, notas emitidas, fornecedores e erros fiscais."
  },
  {
    name: "Produtos",
    icon: "C",
    color: "#24483d",
    text: "Cardapio, produtos, menu, cadastro fiscal e sincronizacao com canais."
  },
  {
    name: "Estoque",
    icon: "E",
    color: "#7a5a2b",
    text: "Movimentacao, recontagem, ingredientes, CMV e alertas de estoque baixo."
  },
  {
    name: "Compras",
    icon: "N",
    color: "#6f5a92",
    text: "Fornecedor, itens fiscais, entrada por XML e vinculos com insumos internos."
  },
  {
    name: "Auditoria",
    icon: "A",
    color: "#5c6862",
    text: "Logs, alerta_sistema e rastreio de erros operacionais ou fiscais."
  }
];

const modules = [
  {
    area: "Atendimento",
    title: "Pedidos",
    icon: "P",
    color: "#d9634f",
    text: "Consulta, status, produtos, pagamentos, motoboy, reimpressao e cancelamento.",
    routes: ["/v1/pedidos/:periodo", "/v1/dados/pedido/:codigo", "/v2/dados/pedido/:pedido"]
  },
  {
    area: "Atendimento",
    title: "Mesas",
    icon: "M",
    color: "#d9634f",
    text: "Controle de comandas, transferencia, zerar mesa e consumo em andamento.",
    routes: ["/v1/mesas/all", "/v2/comanda/:codigo", "/v2/transferencia/produtos/:pedido"]
  },
  {
    area: "Atendimento",
    title: "Novo Pedido",
    icon: "+",
    color: "#d9634f",
    text: "Abertura de pedido, codigo diario, itens, adicionais, sabores e origem.",
    routes: ["/v1/codigo/pedido", "/v1/pedido/produto/:usuario", "/v2/site/grava/pedido"]
  },
  {
    area: "Atendimento",
    title: "Venda Direta",
    icon: "V",
    color: "#d9634f",
    text: "Fluxo PDV para venda rapida, pagamento, cliente e lancamento no caixa.",
    routes: ["/v1/atualiza/dados/pedido", "/v1/caixa/recebimento/pedido/:caixa/:id/:pedido"]
  },
  {
    area: "Financeiro",
    title: "Caixa",
    icon: "$",
    color: "#c58a2f",
    text: "Abertura, sangria, movimentacao, fechamento, recebimentos e historico.",
    routes: ["/v1/caixa/aberto/:usuario", "/v1/caixa/fechamento/:caixa", "/v2/movimentacoes/caixa/:codigo"]
  },
  {
    area: "Financeiro",
    title: "Relatorio de Vendas",
    icon: "R",
    color: "#c58a2f",
    text: "Vendas por periodo, cache de dashboard e leitura de tabelas historicas.",
    routes: ["/v2/dashboard/venda/:dataini/:datafim", "/v1/relatorio/venda/:dataini/:datafim"]
  },
  {
    area: "Financeiro",
    title: "Resultados",
    icon: "%",
    color: "#c58a2f",
    text: "Metricas executivas, fechamento fiado, movimentacao e cancelamentos.",
    routes: ["/v2/resultado/metricas", "/v2/fechamento/fiado", "/v2/pedido/cancelado"]
  },
  {
    area: "Financeiro",
    title: "DashBoard",
    icon: "D",
    color: "#c58a2f",
    text: "Painel principal, previsao, ocupacao de mesas e status operacional.",
    routes: ["/v1/dashboard", "/v2/dashboard/principal", "/v1/util/dashboard/ocupacao"]
  },
  {
    area: "Gestao",
    title: "Despesas",
    icon: "D",
    color: "#326b9a",
    text: "Lancamento, categoria, sugestao, ano e validacao com nota fiscal.",
    routes: ["/v2/despesa", "/v2/despesa/categoria", "/v2/notafiscal/fornecedor/validar"]
  },
  {
    area: "Gestao",
    title: "Fiado",
    icon: "F",
    color: "#326b9a",
    text: "Clientes fiado, consulta, entrada de pagamento e emissao NFC-e fiado.",
    routes: ["/v2/consulta/fiado/:cliente", "/v2/entrada/pagamento/fiado", "/v2/emitir/nfce/fiado"]
  },
  {
    area: "Gestao",
    title: "Auditoria",
    icon: "A",
    color: "#326b9a",
    text: "Logs operacionais, alertas do sistema e erros fiscais agrupados.",
    routes: ["/v2/log/operacao", "/nfce/erros/:data_inicio/:data_fim", "/v2/erro/nfce"]
  },
  {
    area: "Gestao",
    title: "Horario",
    icon: "H",
    color: "#326b9a",
    text: "Horarios, tempo de preparo, parametros de entrega e retirada.",
    routes: ["/v2/cadastro/horario", "/v2/deleta/horario/:dia", "/v2/tempo/entrega/pedido/:codigo"]
  },
  {
    area: "Fiscal",
    title: "Emitidas",
    icon: "N",
    color: "#177f7a",
    text: "Notas emitidas, sincronizacao, contabilidade e consulta por status.",
    routes: ["/v2/nfce/geradas", "/v2/pedidos/nfce/:periodo", "/nfce/notas/sinc"]
  },
  {
    area: "Fiscal",
    title: "DF-e",
    icon: "D",
    color: "#177f7a",
    text: "Consulta, sincronizacao, XML, manifestacao e controle de NSU.",
    routes: ["/dfe/sincronizar/:cnpj", "/dfe/listar/:periodo", "/dfe/manifestar/:chave/:tipo"]
  },
  {
    area: "Fiscal",
    title: "NF-e Entrada",
    icon: "E",
    color: "#177f7a",
    text: "Entrada por XML, validacao, estoque e vinculo com fornecedor.",
    routes: ["/notas-fiscais/:periodo", "/v2/notafiscal/entrada-estoque", "/v2/notafiscal/fornecedor"]
  },
  {
    area: "Fiscal",
    title: "Fornecedor",
    icon: "F",
    color: "#177f7a",
    text: "Cadastro, dossie por periodo e fator dos itens da nota.",
    routes: ["/v2/fornecedores", "/v2/fornecedores/:id", "/v2/fornecedores/:fornecedor/dossie/:periodo"]
  },
  {
    area: "Produtos",
    title: "Produtos",
    icon: "P",
    color: "#24483d",
    text: "Cadastro, busca, foto, fiscal, exclusao e sincronizacao.",
    routes: ["/v2/product", "/v2/produto/fiscal", "/v2/produto/sincronizacao"]
  },
  {
    area: "Produtos",
    title: "Cardapio",
    icon: "C",
    color: "#24483d",
    text: "Categorias, sabores, extras, IA, validacao de hash e canais digitais.",
    routes: ["/v2/category", "/v2/flavor/:category", "/v2/cardapio/ia/processar"]
  },
  {
    area: "Produtos",
    title: "Menu",
    icon: "M",
    color: "#24483d",
    text: "Estrutura de menu e itens por canal: tablet, delivery, totem, QR e TV.",
    routes: ["menu", "menu_item", "produto_id / categoria_id"]
  },
  {
    area: "Produtos",
    title: "Cadastro Fiscal",
    icon: "CF",
    color: "#24483d",
    text: "NCM, CEST, CFOP, CST, CSOSN, ICMS, PIS, COFINS e unidade fiscal.",
    routes: ["/v2/produto/fiscal", "uNFCe.pas", "produto.* fiscal"]
  },
  {
    area: "Produtos",
    title: "Estoque",
    icon: "E",
    color: "#7a5a2b",
    text: "Entrada/saida, recontagem, baixo estoque, analise e CMV.",
    routes: ["/v2/produtos/entrada/saida/:codigo", "/v2/recontagem/estoque", "/v2/cmv/:codigo"]
  },
  {
    area: "Produtos",
    title: "Ingredientes",
    icon: "I",
    color: "#7a5a2b",
    text: "Insumos, fichas tecnicas, composicao, alertas e movimentacao.",
    routes: ["/v2/insulmos", "/v2/insulmos/ficha/:codigo", "/v2/ingredientes/cardapio/processar"]
  }
];

const flows = [
  {
    title: "Pedido -> Caixa",
    kicker: "Operacao",
    text: "O pedido nasce em mesa, delivery, site ou PDV e segue para fechamento, recebimento e caixa.",
    bullets: ["pedido", "pedido_produtos", "caixa_movimento", "caixa_receber"]
  },
  {
    title: "Pedido -> Fiscal",
    kicker: "NFC-e",
    text: "Pedidos faturados podem entrar na fila fiscal, gerar NFC-e, registrar chave, protocolo e eventuais erros.",
    bullets: ["nfce_emite", "nfce_status", "pedido_nfce", "erro_fiscal"]
  },
  {
    title: "Pedido -> Estoque",
    kicker: "Baixa",
    text: "Produtos vendidos baixam estoque direto ou por composicao de ingredientes e adicionais.",
    bullets: ["produto_estoque", "ingredientes_estoque", "produto_ingredientes", "pedido_produto_sap"]
  },
  {
    title: "NF-e Entrada -> Compras",
    kicker: "Entrada fiscal",
    text: "Notas importadas alimentam fornecedor, itens fiscais, despesas e entrada de produto ou ingrediente.",
    bullets: ["nota_fiscal", "nota_fiscal_item", "fornecedor_item", "entrada_estoque"]
  }
];

const areaGrid = document.querySelector("#areaGrid");
const moduleGrid = document.querySelector("#moduleGrid");
const flowRail = document.querySelector("#flowRail");
const flowDetail = document.querySelector("#flowDetail");

function renderAreas() {
  areaGrid.innerHTML = areaData.map((area) => `
    <article class="area-card">
      <span class="area-icon" style="background:${area.color}">${area.icon}</span>
      <h3>${area.name}</h3>
      <p>${area.text}</p>
    </article>
  `).join("");
}

function renderModules(filter = "Todos") {
  const filtered = filter === "Todos" ? modules : modules.filter((module) => module.area === filter);
  moduleGrid.innerHTML = filtered.map((module) => `
    <article class="module-card">
      <header>
        <span class="module-icon" style="background:${module.color}">${module.icon}</span>
        <h3>${module.title}</h3>
      </header>
      <p>${module.text}</p>
      <ul class="routes">
        ${module.routes.map((route) => `<li><code>${route}</code></li>`).join("")}
      </ul>
      <span class="tag">${module.area}</span>
    </article>
  `).join("");
}

function renderFlows(activeIndex = 0) {
  flowRail.innerHTML = flows.map((flow, index) => `
    <button class="flow-step ${index === activeIndex ? "active" : ""}" data-flow="${index}" type="button">
      <span>${flow.title}</span>
      <span>+</span>
    </button>
  `).join("");
  updateFlow(activeIndex);
}

function updateFlow(index) {
  const flow = flows[index];
  document.querySelectorAll(".flow-step").forEach((button) => {
    button.classList.toggle("active", Number(button.dataset.flow) === index);
  });
  flowDetail.innerHTML = `
    <span class="flow-kicker">${flow.kicker}</span>
    <h3>${flow.title}</h3>
    <p>${flow.text}</p>
    <ul>${flow.bullets.map((item) => `<li><code>${item}</code></li>`).join("")}</ul>
  `;
}

document.querySelectorAll(".filter").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".filter").forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
    renderModules(button.dataset.filter);
  });
});

flowRail.addEventListener("click", (event) => {
  const button = event.target.closest(".flow-step");
  if (!button) return;
  updateFlow(Number(button.dataset.flow));
});

function startCanvas() {
  const canvas = document.querySelector("#moduleCanvas");
  const context = canvas.getContext("2d");
  const nodes = [];
  const palette = ["#d9634f", "#c58a2f", "#177f7a", "#326b9a", "#d9efe4"];
  let width = 0;
  let height = 0;
  let pointer = { x: 0, y: 0, active: false };

  function resize() {
    const ratio = window.devicePixelRatio || 1;
    width = canvas.clientWidth;
    height = canvas.clientHeight;
    canvas.width = width * ratio;
    canvas.height = height * ratio;
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    nodes.length = 0;
    const count = Math.max(34, Math.floor(width / 32));
    for (let i = 0; i < count; i += 1) {
      nodes.push({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: (Math.random() - 0.5) * 0.45,
        vy: (Math.random() - 0.5) * 0.45,
        r: 3 + Math.random() * 5,
        color: palette[i % palette.length]
      });
    }
  }

  function frame() {
    context.clearRect(0, 0, width, height);
    context.fillStyle = "#16211d";
    context.fillRect(0, 0, width, height);

    nodes.forEach((node) => {
      node.x += node.vx;
      node.y += node.vy;
      if (node.x < 0 || node.x > width) node.vx *= -1;
      if (node.y < 0 || node.y > height) node.vy *= -1;
      if (pointer.active) {
        const dx = pointer.x - node.x;
        const dy = pointer.y - node.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        if (distance < 170) {
          node.x -= dx * 0.0018;
          node.y -= dy * 0.0018;
        }
      }
    });

    for (let i = 0; i < nodes.length; i += 1) {
      for (let j = i + 1; j < nodes.length; j += 1) {
        const a = nodes[i];
        const b = nodes[j];
        const dx = a.x - b.x;
        const dy = a.y - b.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        if (distance < 150) {
          context.strokeStyle = `rgba(217, 239, 228, ${1 - distance / 150})`;
          context.lineWidth = 1;
          context.beginPath();
          context.moveTo(a.x, a.y);
          context.lineTo(b.x, b.y);
          context.stroke();
        }
      }
    }

    nodes.forEach((node) => {
      context.fillStyle = node.color;
      context.beginPath();
      context.arc(node.x, node.y, node.r, 0, Math.PI * 2);
      context.fill();
    });

    requestAnimationFrame(frame);
  }

  window.addEventListener("resize", resize);
  canvas.addEventListener("pointermove", (event) => {
    const rect = canvas.getBoundingClientRect();
    pointer = { x: event.clientX - rect.left, y: event.clientY - rect.top, active: true };
  });
  canvas.addEventListener("pointerleave", () => {
    pointer.active = false;
  });
  resize();
  frame();
}

renderAreas();
renderModules();
renderFlows();
startCanvas();
