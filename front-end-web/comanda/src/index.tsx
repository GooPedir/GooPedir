import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { Home } from './componente/home/home';


const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
    {/* <App /> */}
    <Home/>
  </React.StrictMode>
);

