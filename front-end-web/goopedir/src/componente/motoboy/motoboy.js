import { useState } from "react";
import {
  Flex,
  Heading,
  Input,
  Button,
  InputGroup,
  Stack,
  InputLeftElement,
  chakra,
  Box,
  Link,
  Avatar,
  FormControl,
  FormHelperText,
  InputRightElement,
  Text
} from "@chakra-ui/react";
import { FaUserAlt, FaLock } from "react-icons/fa";
import axios from "axios";


const API = axios.create({
  baseURL: "https://goopedir.com/ws/v1/",
})

function pad(num, size) {
  num = num.toString();
  while (num.length < size) num = "0" + num;
  return num;
}


const CFaLock = chakra(FaLock);

var senha = '';

const Motoboy = () => {
    const [showPassword, setShowPassword] = useState(false);
    const [Pedido, setPedido] = useState('');
    const [CodigoPedido, setCodigoPedido] = useState('');
    const [NomeCliente, setNomeCliente] = useState('');
    const [EnderecoCliente, setEnderecoCliente] = useState('');
    const [Total, setTotal] = useState('');
    const [UserId, setUserId] = useState(43);
    const [IdPedido, setIdPedido] = useState(0);
    const [CodigoMotoboy, setCodigoMotoboy] = useState(0);
    const [Empresa, setEmpresa] = useState('');
    const [NomeMotoboy, setNomeMotoboy] = useState('');
    const [NomeMotoboyPedido, setNomeMotoboyPedido] = useState('');

    const [senha, setSenha] = useState(localStorage.getItem("@goopedir/senha"));

  const handleShowClick = () => setShowPassword(!showPassword);

// function setSenha(senhaLocal){
//     senha = senhaLocal;
// }

function Login(){
 console.log(senha);   
//  motoboy.php?senha=S043-047
API.get('motoboy.php?senha='+senha).then(
  function (response) {
    console.log(response.data[0]);
    setCodigoMotoboy(response.data[0]['id']);
    setEmpresa(response.data[0][8]);
    setNomeMotoboy(response.data[0]['deliveryman_name']);
    localStorage.setItem("@goopedir/senha",senha);    
  })
}


const LoginMotoboy = () => {

return <Flex
      flexDirection="column"
      width="100wh"
      height="100vh"
      backgroundColor="gray.200"
      justifyContent="center"
      alignItems="center"
    >
      <Stack
        flexDir="column"
        mb="2"
        justifyContent="center"
        alignItems="center"
      >
        <Avatar bg="red.500" />
        <Heading color="red.400">Acesso Motoboy</Heading>
        <Box minW={{ base: "90%", md: "468px" }}>
          
            <Stack
              spacing={4}
              p="1rem"
              backgroundColor="whiteAlpha.900"
              boxShadow="md"
            >

              <div>
                <InputGroup>
                  <InputLeftElement
                    pointerEvents="none"
                    color="gray.300"
                    children={<CFaLock color="gray.300" />}
                  />
                  <Input
                    type={showPassword ? "text" : "password"}
                    placeholder="Senha"
                    onChange={(e) => setSenha(e.target.value)}
                    value={senha}
                  />
                  <InputRightElement width="4.5rem">
                    <Button h="1.75rem" size="sm" onClick={handleShowClick}>
                      {showPassword ? "Ocutar" : "Mostrar"}
                    </Button>
                  </InputRightElement>
                </InputGroup>

              </div>
              <Button
                borderRadius={20}
                type="submit"
                variant="solid"
                colorScheme="red"
                width="full"
                onClick={Login}
                
              >
                Acessar
              </Button>
            </Stack>
        
        </Box>
      </Stack>

    </Flex>

}

const PedidoMotoboy = () =>{
  return <Flex
  flexDirection="column"
  width="100wh"
  height="100vh"
  backgroundColor="gray.200"
  justifyContent="center"
  alignItems="center"
>
  <Stack
    flexDir="column"
    mb="2"
    justifyContent="center"
    alignItems="center"
  >
    
    <Heading color="red.400">{Empresa}</Heading>
    <Text color="black.400">{NomeMotoboy}</Text>
    <Heading color="red.400">Pedido</Heading>
    <Box minW={{ base: "90%", md: "468px" }}>
      
        <Stack
          spacing={4}
          p="1rem"
          backgroundColor="whiteAlpha.900"
          boxShadow="md"
        >

          <div>
            <InputGroup>
              <Input
                type={"text"}
                placeholder="Código do Pedido"
                onChange={(e) => setPedido(e.target.value)}
                value={Pedido}
              />
            </InputGroup>

          </div>
          <Button
            borderRadius={20}
            type="submit"
            variant="solid"
            colorScheme="green"
            width="full"
            onClick={ConsultarPedido}           
          >
            Consultar
          </Button>
          <Button
            borderRadius={35}
            type="submit"
            variant="solid"
            colorScheme="red"
            width="full"
            onClick={EnviaMotoboyPedido}                       
          >
            Saiu Para Entrega
          </Button>          
        </Stack>
    
    </Box>
  </Stack>
  <Box minW={{ base: "90%", md: "468px" }}>
  <Stack
          spacing={4}
          p="1rem"
          backgroundColor="whiteAlpha.900"
          boxShadow="md"
        >
  <Text color="black.400">{CodigoPedido}</Text>
  <Text color="black.400">{NomeCliente}</Text>
  <Text color="black.400">{EnderecoCliente}</Text>
  <Text color="black.400">{Total}</Text>
  <Text color="black.400">{NomeMotoboyPedido}</Text>
  </Stack>
  </Box>


</Flex>  
}

function Limpa(){
  setCodigoPedido('');
  setNomeCliente('');
  setEnderecoCliente('');
  setTotal('');
  setNomeMotoboyPedido('');
  setIdPedido(0);
}

const ConsultarPedido = () =>{
  Limpa();
  try {
  API.get('pedidosm/'+UserId+'-'+pad(Pedido,5)+'/a').then(
    function (response) {
      if (response.data){
        console.log(response.data[0]);
        var nome = response.data[0]['nome'];
        nome = nome.replace("(", "");
        nome = nome.replace(")", "");
        nome = nome.replace("-", "");
        nome = nome.replace("_", "");
        nome = nome.replace("&", "");
        nome = nome.replace("%20", " ");
        nome = nome.replace("%", " ");
        
        setCodigoPedido('Pedido: '+response.data[0]['codigo_pedido']);
        setNomeCliente(response.data[0]['telefone']+' - '+nome);
        setEnderecoCliente(response.data[0]['rua']+' - '+response.data[0]['bairro']+' R$ '+response.data[0]['valor_taxa'].toLocaleString('pt-br', {minimumFractionDigits: 2}));
        setTotal('R$ '+response.data[0]['total'].toLocaleString('pt-br', {minimumFractionDigits: 2}));
        setIdPedido(response.data[0]['id']);
        setNomeMotoboyPedido('Motoboy: '+response.data[0]['deliveryman_name']);
      } else {
        setCodigoPedido('Pedido: Não existe!');
        setPedido('');
      }
    })
  } catch(e){
    
  }  
}

const EnviaMotoboyPedido = () =>{
  API.get('gravamotoboy.php?pedido='+IdPedido+'&motoboy='+CodigoMotoboy+'&user='+UserId).then(
    function (response) {
      ConsultarPedido();
      setPedido('');
    }
  )
}

  return (
    <>
      {/* <PedidoMotoboy/> */}
      {CodigoMotoboy == 0 ? <LoginMotoboy/> : <PedidoMotoboy/> }
      {/* <LoginMotoboy/> */}
    </>
  );
};

export default Motoboy;
