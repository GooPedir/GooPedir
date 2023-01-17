
export const Api = axios.create({
  baseURL: "http://localhost:2121/"
//   ,headers: { 'authorization': 'bearer ' + GetCookie('token') }
})