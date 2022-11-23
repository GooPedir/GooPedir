import { useState } from "react";
import styled from "styled-components";
import px2vw from "../../utils/px2vw";

export const Card = styled.div`
  flex-direction: row;  
  display: inline-block;
  border: 1px solid red;
  border-radius: 8px;
  margin-left: ${px2vw(5)};
  padding: ${px2vw(5)};
    
  a {  
  width: 50px;
  text-decoration: none;
  color: #fff;
}

`;

export const Titulo = styled.h3`
  color: ${props => props.corfonte};
  /* background-color: ${props => props.corfonte}; */
  font-size: 2rem;
  text-align: lefth;
  flex-direction: column;

  @media (min-width: 1024px) {
    font-size: 1.5rem;
  }

`;





export default function Categoria(dados) {
  

    return (    
        <>                 
        {dados.dados.map(box => (
         
       <Card key={box.id}>
         <a href={"categoria-"+box.id}>{box.nome_cat}</a>     
       </Card>
            // <Card key={box.id} corfonte={dados.corfonte} corfundo={dados.corfundo} onClick={(e) => test(box.id)}>
            //   <Titulo corfonte={dados.corfonte} corfundo={dados.corfundo}>{box.nome_cat}</Titulo>
            //   {/* <BoxText>{box.text}</BoxText> */}
            // </Card>
          ))}
      {/* </BarraSuperior> */}
      </>  
    );
  }