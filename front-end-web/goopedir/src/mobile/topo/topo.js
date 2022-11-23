import {
    Drawer,
    DrawerBody,
    DrawerFooter,
    DrawerHeader,
    DrawerOverlay,
    DrawerContent,
    DrawerCloseButton,
    CloseButton,
    useDisclosure,
    Button,
    Text,
    Alert,
    AlertIcon,
    AlertTitle,
    AlertDescription,
  } from '@chakra-ui/react'
import  { useState, memo } from 'react';
import styled from "styled-components";
import px2vw from "../../utils/px2vw";
import axios from "axios";
import ProdutosMobile from './produtos';

export const BarraSuperior = styled.div`
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  
  /* margin: ${px2vw(32)}; */
  width: 100%;
  height: ${px2vw(80)};
  background-color: rgb(164,0,27);

  @media (min-width: 1024px) {
    flex-wrap: nowrap;
    
  } 
  @media (max-width: 1024px) {
    height: ${px2vw(100)};
  }
`;


export const Container = styled.div`
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  margin: ${px2vw(5)};
  max-width: 100%;

  @media (min-width: 1024px) {
    flex-wrap: nowrap;
  }
`;

export const Box = styled.div`
  display: flex;
  width: ${px2vw(425)};
  min-height: ${px2vw(300)};
  flex-direction: column;
  padding: ${px2vw(5)};
  margin: ${px2vw(5)};
  background-color: ${props => props.cor};
  height: 100%;
  border-radius: 15px;
  box-shadow: black 0.2em 0.2em 0.2em;

  @media (min-width: 768px) {
    width: ${px2vw(400)};
    min-height: ${px2vw(200)};
    height: 100%;
    /* background-color: red; */
  }

  @media (min-width: 1024px) {
    width: ${px2vw(200)};
    min-height: ${px2vw(200)};
    height: 100%;
    /* background-color: blue; */
  }

  &:hover {
    background-color: rgb(63,72,204,0.8);
    cursor: pointer;
  }  
`;

export const BoxTitle = styled.h3`
  color: #fff;
  font-size: 2.5rem;
  text-align: center;
  text-shadow: black 0.1em 0.1em 0.1em;

  @media (min-width: 1024px) {
    font-size: 0.8rem;
  }

`;

export const BoxText = styled.p`
  margin-top: ${px2vw(20)};
  color: #fff;
  font-size: 1.5rem;
  text-align: right;
  padding: ${px2vw(5)};
  margin: ${px2vw(5)};

  @media (min-width: 1024px) {
    font-size: 1rem;
  }
`;

const BaseURL = "http://192.168.3.251:2121/";
const API = axios.create({
    baseURL: BaseURL,
  }) 

 var atual = 0; 
 var DadosLocal = [];




var DadosLocal = [];

function AbrirMesaSelecionada(mesa) { 
console.log(mesa);
  return (
  <>
  <h1>XXX</h1>
  </>)
}


function CarregaMesa(mesa){

if (mesa.dados.totMesa>0){
  var cor = 'rgb(164,0,27,0.80)';
  var status = 'Em Aberto'
} else {
  var cor = 'rgb(34,164,33,0.8)';
  var status = 'Livre'
}

const handleClick = (idLocalMesa)=> {
  // setSize(newSize)

    API.get('v1/produtos/pedido/1/'+idLocalMesa).then(
      function (response) {
        DadosLocal = response.data;
                 
      }) 

      console.log(idLocalMesa);
       
  
}

  return(
    <>
          <Box key={mesa.dados.idMesa} cor={cor} onClick={() => AbrirMesaSelecionada(mesa.dados.idMesa)}>
          <BoxTitle>{mesa.dados.descricao} {mesa.dados.nrMesa}</BoxTitle>
          <BoxText>{mesa.dados.totMesa.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'})}</BoxText>
          <BoxText>{status}</BoxText>                    
          </Box>
          {/* ABRIR */}  
    </>
  )
}
  
export default function TopoMobile(mesa) {       
  const [ProdutosMesa, setProdutosMesa] = useState(DadosLocal);
  const { isOpen, onOpen, onClose } = useDisclosure()
    return (    
        <>

          <BarraSuperior>
            <BoxTitle>GooPedir</BoxTitle>
         </BarraSuperior>
         <Container>


         {
         
         mesa.data.map(mesa => (
          <CarregaMesa dados={mesa}/>        
      ))}                                                  
        </Container>
       
     
      </>  
    );
  }