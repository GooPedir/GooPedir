
import styled from "styled-components";
import px2vw from "../../utils/px2vw";
import Categoria from "../categoria/categoria";

var altura = window.screen.height;
var largura = window.screen.width;

export const DivCorpo = styled.div`
  display: flex;  
  justify-content: center;
  align-items: center;  
  flex-direction: column;

  padding: ${px2vw(15)};
  background-color: #000000;
  height: 600px;
  width: ${largura};   

  //Celular
   @media (max-width: 768px) {

    
  } 

  @media (min-width: 768px) {
    margin-left: ${px2vw(350)};
  margin-right: ${px2vw(350)};
    
   
  }

nav, scroll-container {
  display: block;
  margin: 0 auto;
  text-align: center;
}
nav {
  width: 339px;
  padding: 5px;
  border: 1px solid black;
}
scroll-container {
  display: block;
  width: 350px;
  height: 200px;
  overflow-y: scroll;
  scroll-behavior: smooth;
}
scroll-page {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  font-size: 5em;
}

`;

export const DivCategoria = styled.div`
  display: flex;  

  padding: ${px2vw(15)};
  background-color: #000000;
  height: 50px;  
  width: ${largura};

  overflow-y: scroll;
  scroll-behavior: auto;

  box-sizing: border-box;

`;

export const Test = styled.div`  
  width: 300%;

  box-sizing: border-box;
`;


export default function Corpo(dados) {
console.log(dados);
    return (    
        <>  
         <DivCategoria>
 <Test >
<Categoria corfundo={dados.corfundo} corfonte={dados.corfonte} dados={dados.dados}/> 
</Test>
</DivCategoria>                   

{/* <scroll-container>
  <scroll-page id="page-1">1</scroll-page>
  <scroll-page id="page-2">2</scroll-page>
  <scroll-page id="page-3">3</scroll-page>
</scroll-container>   */}

      </>  
    );
  }