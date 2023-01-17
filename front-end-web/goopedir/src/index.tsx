import ReactDOM from 'react-dom/client';
import App from './App';
import Mobile from './Mobile';
import Motoboy from './componente/motoboy/motoboy';
import { ChakraProvider } from '@chakra-ui/react'




const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <ChakraProvider>
    <Mobile />
    {/* <Motoboy/> */}
  </ChakraProvider>
);

