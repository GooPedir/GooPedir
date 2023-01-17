import { Box, Center, Heading, Text } from '@chakra-ui/layout'
import { SimpleGrid } from '@chakra-ui/react'
import { Api } from '../util/context/api'

export function Home(){

   function getMesas(){
    Api.get('').then(
      function(response){
        
      }
    )
   }


    return (
        <>

        <Box h='3rem' w='100%' bg='red' color='white'>GooPedir</Box>
      
  <SimpleGrid columns={4} spacing={10}>
  <Box bg='tomato' height='80px'>
  

  </Box>
  <Center  bg='tomato' height='80px'>

  <Text>
    1
  </Text>

  </Center>
  <Box bg='tomato' height='80px'></Box>
  <Box bg='tomato' height='80px'></Box>
  <Box bg='tomato' height='80px'></Box>
  <Box bg='tomato' height='80px'></Box>
  <Box bg='tomato' height='80px'></Box>
  <Box bg='tomato' height='80px'></Box>
  <Box bg='tomato' height='80px'></Box>
</SimpleGrid>
        </>
    )
}