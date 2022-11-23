import { createGlobalStyle } from "styled-components";
import px2vw from "../utils/px2vw";

export const Global = createGlobalStyle`
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    /* background-color: #7159c1; */
  }
  :root {
      font-size: ${px2vw(24)};

      @media (min-width: 768px) {
        font-size: ${px2vw(18)};
      }

      @media (min-width: 1024px) {
        font-size: ${px2vw(16)};
      }
    }
    header {
        background: yellow;        
        grid-area: h;
      }

      main {
        background: blue;        
        grid-area: m;
      }

      aside {
        background: green;             
        grid-area: a;
      }

      footer {
        background: red; 
        grid-area: f;            
      }   

 .container{
  display: grid;
  grid-template-columns: 3fr 1fr;
  grid-template-rows: 15vh 30vh 50vh 5vh;
  /* grid-gap: 20px 50px; */
  grid-template-areas: "h h"
                       "m m"
                       "a a"
                       "f f"
 }  

 .container-sidebar{
  display: grid;
  width: 100vw;
  height: 5vh; 
  background-color: black;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr;
  grid-gap: 5px;
  
  
  /* grid-gap: 20px 50px; */
  /* grid-template-areas: "h m" */
  /* grid-template-rows: 15vh 30vh 50vh 5vh;  */
 }

 .container-sidebar > div{
  background-color: #ffffff;
 }
 
 p { background: gold; word-wrap: break-word; }
 
`;

export default Global;