import styled from "styled-components";
import px2vw from "../../utils/px2vw";
import { ValidaAbertura, HorarioAbertura, HorarioFechamento } from "../funcoes/funcoes";


import { BiCaretDown } from "react-icons/bi";
import { useState } from "react";

import { Button } from '@chakra-ui/react'




export const Container = styled.div`
  display: grid;
  height: 100%;
  width: 100%;
  background-color: red;  
  grid-template-columns: 3fr 50px;
  grid-template-rows: 65px 55px 1fr;
  grid-gap: 1px;
`;

export const Box = styled.div`
  background-color: ${props => props.corfundo};
`;

export const BoxSelecaoTipoEntrega = styled.div`
  background-color: red;
  margin: 10px 5px 5px 5px;
  height: 35px;
`;

export const ContainerSelecaoTipoEntrega = styled.div`
  display: grid;
  height: 100%;
  width: 100%;
  /* background-color: Black;   */
  grid-template-columns: 3fr 45px;
  
`;

export const BoxWhiteLadoA = styled.div`
  background: white;
  height: 100%;
  width: 100%;
  box-sizing: border-box;
  border-style: solid;
  border-color: black;
  border-width: 1px 0px 1px 1px;
  border-radius: 10px 0px 0px 10px;  
`;

export const BoxWhiteLadoB = styled.div`
  background: white;
  height: 100%;
  width: 100%;
  box-sizing: border-box;
  border-style: solid;
  border-color: black;
  border-width: 1px 1px 1px 0px;
  border-radius: 0px 10px 10px 0px;  
`;

export const TitleSelecaoTipoEntrega = styled.h3`
  color: ${props => props.colorfonte};
  font-size: 16px;
  /* text-align: center; */
  flex-direction: column;
  margin: 5px 0px 0px 10px;
  
`;


export const Logo = styled.div`
  border-radius: 50%;  
  width: 45px;
  height: 45px;
  flex-direction: column;
  margin: 10px 0px 0px 0px;
  /* margin: ${px2vw(20)};
  width: ${px2vw(200)};
  height: ${px2vw(200)}; */
  background: url(${props => props.url}) center/cover no-repeat;

`;

export const BoxTitle = styled.h3`
  color: ${props => props.colorfonte};
  font-size: 3rem;
  /* text-align: center; */
  flex-direction: column;
  margin-left: 20px;
  
`;

export const BoxAbertura = styled.h3`
  color: ${props => props.colorfonte};
  font-size: 3rem;
  text-align: right;;
  flex-direction: column;
  margin-right: 20px;
  
`;



function shoot(){
  console.log('Clicou')
}


export default function Topo(dados) {


function StatusLoja(){
    if (ValidaAbertura(dados.dados)){
      return 'Aberto, Fecha ás '+HorarioFechamento(dados.dados)
    } else{
      return 'Fechado, Abre às '+HorarioAbertura(dados.dados)
    }
}



const [TipoEntrega, setTipoEntrega] = useState('Delivery');

    return (    
        <>
        <Container>
        <Box><BoxTitle key={1} colorfonte={dados.colorfonte}> {dados.nomeempresa}</BoxTitle>
        <BoxAbertura key={2} colorfonte={dados.colorfonte}> {StatusLoja()}</BoxAbertura></Box>
        <Box><Logo url={dados.urllog}></Logo></Box>

        <Box onClick={shoot()}>
            <BoxSelecaoTipoEntrega>
              <ContainerSelecaoTipoEntrega>
              <BoxWhiteLadoA>
                <TitleSelecaoTipoEntrega>{TipoEntrega}</TitleSelecaoTipoEntrega>
              </BoxWhiteLadoA>
               <BoxWhiteLadoB>
                <BiCaretDown size={"35px"}/>
               </BoxWhiteLadoB>
              </ContainerSelecaoTipoEntrega>
            </BoxSelecaoTipoEntrega>
          </Box>
        <Box></Box>
        <Box></Box>
        <Box></Box>


        </Container>
        {/* <BarraSuperior key={1} corfundo={dados.corfundo}>
        
        
        
        
        <BoxStatus key={1} colorfonte={dados.colorfonte}> {dados.nomeempresa}</BoxStatus>
         */}
            
        {/* {boxData.map(box => (
          <Box key={box.id} bgColor={box.bgColor}>
            <BoxTitle>{box.title}</BoxTitle>
            <BoxText>{box.text}</BoxText>
          </Box>
        ))} */}
      {/* </BarraSuperior> */}
      </>  
    );
  }