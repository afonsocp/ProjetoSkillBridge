// Global Solution 2025/2 - SkillBridge Database (MongoDB)
// Script de importacao para a colecao "recomendacoes"

db = db.getSiblingDB("skillbridge");

db.recomendacoes.drop();

db.recomendacoes.insertMany([
  {
    nome: "Afonso Pereira",
    email: "afonso@email.com",
    competencias: ["Java", "Spring Boot", "SQL"],
    cursosRecomendados: [
      { nome: "Spring Boot Avancado", duracao: 40 },
      { nome: "Banco de Dados Oracle", duracao: 30 }
    ],
    vagasRelacionadas: [
      { titulo: "Desenvolvedor Java", empresa: "TechLabs" }
    ],
    geradoEm: new Date(),
    origemRecomendacao: "motor-ia",
    nivelCarreira: "Pleno"
  },
  {
    nome: "Bianca Rodrigues",
    email: "bianca.rodrigues@email.com",
    competencias: ["Python", "Data Analysis", "Power BI"],
    cursosRecomendados: [
      { nome: "Python para Ciencia de Dados", duracao: 50 },
      { nome: "Visualizacao de Dados com Power BI", duracao: 24 }
    ],
    vagasRelacionadas: [
      { titulo: "Analista de Dados", empresa: "Insight Analytics" },
      { titulo: "Business Intelligence Specialist", empresa: "FutureCorp" }
    ],
    geradoEm: new Date(),
    origemRecomendacao: "motor-ia",
    nivelCarreira: "Senior"
  },
  {
    nome: "Carlos Lima",
    email: "carlos.lima@email.com",
    competencias: ["UX", "UI", "Figma"],
    cursosRecomendados: [
      { nome: "UX Strategy", duracao: 20 },
      { nome: "Design Systems com Figma", duracao: 18 }
    ],
    vagasRelacionadas: [
      { titulo: "Product Designer", empresa: "VisionX" }
    ],
    geradoEm: new Date(),
    origemRecomendacao: "motor-ia",
    nivelCarreira: "Junior"
  }
]);

printjson(db.recomendacoes.find().toArray());


