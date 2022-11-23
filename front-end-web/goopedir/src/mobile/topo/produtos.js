import {
    Button,
    Text,
    IconButton,
    Divider,
    Modal,
    ModalOverlay,
    ModalContent,
    ModalHeader,
    ModalFooter,
    ModalBody,
    ModalCloseButton,
    useDisclosure, 
  } from '@chakra-ui/react'
import axios from 'axios';
import { useState, memo } from 'react';

import { AiOutlineDelete } from "react-icons/ai";

const BaseURL = "http://192.168.3.251:2121/";
const API = axios.create({
    baseURL: BaseURL,
  }) 






var DadosMesa = [];    

function BackdropExample(dados) {
    console.log(dados)
    const OverlayOne = () => (
      <ModalOverlay
        bg='blackAlpha.300'
        backdropFilter='blur(10px) hue-rotate(90deg)'
      />
    )
  
    const OverlayTwo = () => (
      <ModalOverlay
        bg='none'
        // backdropFilter='auto'
        backdropInvert='80%'
        backdropBlur='20px'
      />
    )

    
  
    const { isOpen, onOpen, onClose } = useDisclosure()
    const [overlay, setOverlay] = useState(<OverlayOne />)

    function Excluir(codigo){
        // API.delete('/v1/pedido/produto/'+codigo).then(        
        //     function (response) {
        //     console.log(response);     
        //     })   
            onClose();
    }    
  
    return (
      <>
       <IconButton aria-label='Search database' colorScheme='red' icon={<AiOutlineDelete />} 
       onClick={() => {
        setOverlay(<OverlayOne />)
        onOpen()
      }}/> 
        <Modal isCentered isOpen={isOpen} onClose={onClose}>
          {overlay}
          <ModalContent>
            <ModalHeader>Deseja realmente exluir o produto?</ModalHeader>
            <ModalCloseButton />
            <ModalBody>
              <Text>{dados.data.nomeProduto}</Text>
            </ModalBody>
            <ModalFooter>
            <Button onClick={onClose}>Cancelar</Button>
            <Button onClick={Excluir(dados.data.codigo)}>Excluir</Button>
            </ModalFooter>
          </ModalContent>
        </Modal>
      </>
    )
  }









function ProdutosMobile(data) {
    
    const [DadosMesa, setDadosMesa] = useState([]);

    // API.get('/v1/produtos/pedido/itens/'+data.data.codigo).then(        
    //     function (response) {
    //     setDadosMesa(response.data)
     
    //     })        
    // console.log(data.data.valorTotal.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'}));
    return (  
        <>
        <div>
                <Text fontSize='2xl'>{data.data.quantidade}un - {data.data.nomeProduto}</Text>
                {DadosMesa.map(mesa => (
                <>
                <Text fontSize='2xl'>{mesa.dados}</Text>
                
                </>              
                ))}    
                <Text fontSize='2xl'>R$ {data.data.valorTotal.toLocaleString('pt-br')}</Text>   
                {/* <Button colorScheme='red'>Excluir Produto</Button>  */}
                <BackdropExample data={data.data}/>               
                <Divider />                            
        </div>
        </>
    )

}    

export default memo(ProdutosMobile)